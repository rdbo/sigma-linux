# frozen_string_literal: true

require "io/console"
require "monitor"

module Sigma
  # Everything the user sees goes through here: colours, glyphs, stage frames,
  # live task lines and boxes. It adapts to where it is writing:
  #
  #   * an interactive terminal gets colour, a spinner and a live tail of the
  #     running command's output on a single line;
  #   * verbose mode streams every output line under its task instead;
  #   * pipes and CI logs get plain, append-only lines plus a heartbeat so long
  #     steps don't look hung.
  class UI
    SPINNER = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
    HEARTBEAT = 60 # seconds between "still running" lines when not on a TTY
    LABEL_WIDTH = 30

    # [truecolor RGB, 256-colour index]
    PALETTE = {
      accent: [[0, 255, 200], 49],   # Sigma teal, colour 14 of the VT palette
      ok:     [[80, 250, 160], 85],
      warn:   [[255, 200, 87], 221],
      error:  [[255, 95, 95], 203],
      muted:  [[112, 122, 135], 244],
      text:   [[222, 226, 232], 254]
    }.freeze

    GLYPHS = {
      ok: "✓", fail: "✗", skip: "○", warn: "!", run: "▸", info: "·",
      frame_top: "┌", frame_mid: "│", frame_end: "└"
    }.freeze

    attr_reader :verbose

    def initialize(out: $stdout, verbose: false, color: nil)
      @out = out
      @tty = out.tty?
      @verbose = verbose
      @depth = detect_color_depth(color)
      @lock = Monitor.new
      @in_stage = false
    end

    def tty? = @tty
    def color? = @depth.positive?

    # -- primitives -----------------------------------------------------------

    def paint(text, role = nil, bold: false, dim: false)
      return text.to_s if @depth.zero? || (role.nil? && !bold && !dim)

      codes = []
      codes << "1" if bold
      codes << "2" if dim
      if role
        rgb, index = PALETTE.fetch(role)
        codes << (@depth == 24 ? "38;2;#{rgb.join(";")}" : "38;5;#{index}")
      end
      "\e[#{codes.join(";")}m#{text}\e[0m"
    end

    def say(line = "")
      @lock.synchronize { @out.puts(line) }
    end

    def blank = say

    def width
      return 100 unless @tty

      IO.console&.winsize&.last.then { |w| w.nil? || w.zero? ? 100 : w }
    rescue StandardError
      100
    end

    # -- page furniture ---------------------------------------------------------

    def banner(title, details = [])
      blank
      say "  #{paint("Σ", :accent, bold: true)}  #{paint(title, :text, bold: true)}"
      say "     #{details.map { |d| paint(d, :muted) }.join(paint(" · ", :muted))}" unless details.empty?
      blank
    end

    # A framed group of tasks, e.g. one pipeline stage:
    #
    #   ┌ packages · local APK repository
    #   │ ✓ initrdbo 0.5.3-r0                 up to date
    #   └ 1 package · 3s
    def stage(name, description = nil)
      say " #{frame(:frame_top)} #{paint(name, :accent, bold: true)}" \
          "#{description ? paint(" · #{description}", :muted) : ""}"
      @in_stage = true
      started = clock
      summary = yield
      @in_stage = false
      say " #{frame(:frame_end)} #{paint([summary, duration(clock - started)].compact.join(" · "), :muted)}"
      blank
    rescue Exception # rubocop:disable Lint/RescueException -- close the frame on Ctrl-C too
      @in_stage = false
      say " #{frame(:frame_end)} #{paint("failed", :error)}"
      blank
      raise
    end

    def stage_skipped(name, reason)
      say " #{paint(GLYPHS[:skip], :muted)} #{paint(name, :accent)}#{paint(" · #{reason}", :muted)}"
      blank
    end

    # A single line inside a stage frame, for things that are not tasks.
    def line(glyph, label, note = nil, role: :muted)
      say "#{prefix}#{paint(GLYPHS.fetch(glyph), role)} #{pad(label)}#{note ? paint(note, :muted) : ""}"
    end

    def note(text) = say("#{prefix}  #{paint(text, :muted)}")
    def warn(text) = say("#{prefix}#{paint(GLYPHS[:warn], :warn, bold: true)} #{paint(text, :warn)}")

    # Key/value listing, used by `sigma config` and `sigma status`.
    def table(rows, indent: 2)
      key_width = rows.map { |k, _| k.to_s.length }.max || 0
      rows.each do |key, value|
        say "#{" " * indent}#{paint(key.to_s.ljust(key_width), :muted)}  #{value}"
      end
    end

    # A rounded box. Lines are truncated to the terminal width.
    def box(lines, title: nil, role: :accent)
      inner = [width - 6, 40].max
      content = lines.flat_map { |l| l.to_s.empty? ? [""] : l.to_s.split("\n", -1) }
      body_width = [content.map { |l| visible_length(l) }.max.to_i, visible_length(title.to_s) + 2].max
      body_width = body_width.clamp(20, inner)

      top = title ? "╭─ #{title} #{"─" * [body_width - visible_length(title) - 1, 0].max}╮" : "╭#{"─" * (body_width + 2)}╮"
      say "  #{paint(top, role)}"
      content.each do |l|
        l = truncate(l, body_width)
        say "  #{paint("│", role)} #{l}#{" " * (body_width - visible_length(l))} #{paint("│", role)}"
      end
      say "  #{paint("╰#{"─" * (body_width + 2)}╯", role)}"
    end

    # -- tasks ------------------------------------------------------------------

    # Runs the block as a named task with a live status line, and returns the
    # block's value. The block receives the Task, which commands write their
    # output through (see Shell). Exceptions mark the task failed and re-raise.
    def task(label, log: nil)
      task = Task.new(self, label, log)
      task.start
      result = yield task
      task.finish
      result
    rescue Exception => e # rubocop:disable Lint/RescueException -- show the ✗ on Ctrl-C too
      task&.fail(e)
      raise
    end

    # -- formatting helpers (public: stages use them for notes) ------------------

    def duration(seconds)
      seconds = seconds.to_f
      return format("%.1fs", seconds) if seconds < 10
      return "#{seconds.round}s" if seconds < 60

      minutes, secs = seconds.round.divmod(60)
      return format("%dm %02ds", minutes, secs) if minutes < 60

      hours, minutes = minutes.divmod(60)
      format("%dh %02dm", hours, minutes)
    end

    def bytes(count)
      units = %w[B KB MB GB TB]
      value = count.to_f
      unit = units.shift
      while value >= 1024 && !units.empty?
        value /= 1024
        unit = units.shift
      end
      unit == "B" ? "#{count} B" : format("%.1f %s", value, unit)
    end

    def plural(count, word, plural_word = "#{word}s")
      "#{count} #{count == 1 ? word : plural_word}"
    end

    # -- internals used by Task -------------------------------------------------

    def prefix
      @in_stage ? " #{frame(:frame_mid)} " : "  "
    end

    def pad(label, width = LABEL_WIDTH)
      label = label.to_s
      visible_length(label) >= width ? "#{label} " : label + " " * (width - visible_length(label))
    end

    def visible_length(text)
      text.to_s.gsub(/\e\[[0-9;?]*[A-Za-z]/, "").length
    end

    # Word-wraps plain text (no escape codes) to +max+ columns.
    def wrap(text, max)
      text.to_s.split("\n").flat_map do |paragraph|
        paragraph.split(/(?<=\s)/).each_with_object([+""]) do |word, lines|
          lines << +"" if !lines.last.empty? && (lines.last + word.rstrip).length > max
          lines.last << word
        end.map(&:rstrip)
      end
    end

    def truncate(text, max)
      return text if visible_length(text) <= max

      plain = text.gsub(/\e\[[0-9;?]*[A-Za-z]/, "")
      "#{plain[0, [max - 1, 0].max]}…"
    end

    def synchronize(&) = @lock.synchronize(&)
    def raw(text) = @out.print(text)
    def flush = @out.flush

    def clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    private

    def frame(part) = paint(GLYPHS.fetch(part), :accent)

    def detect_color_depth(requested)
      return 0 if requested == false
      return 0 if ENV.key?("NO_COLOR") && !ENV["NO_COLOR"].empty?
      return 0 unless @tty || ENV["FORCE_COLOR"] || requested
      return 24 if ENV["COLORTERM"].to_s.match?(/truecolor|24bit/i)

      256
    end

    # One running task: owns its status line and, when given, its log file.
    class Task
      attr_reader :label, :log
      attr_accessor :detail

      def initialize(ui, label, log)
        @ui = ui
        @label = label
        @log = log
        @tail = nil
        @detail = nil
        @skipped = nil
      end

      def start
        @started = @ui.clock
        if live?
          @ui.synchronize { @ui.raw("\e[?25l") } # hide cursor while spinning
          @spinner = Thread.new { spin }
        else
          @ui.say "#{@ui.prefix}#{@ui.paint(GLYPHS[:run], :accent)} #{@label}"
          @heartbeat = Thread.new { beat } unless @ui.verbose
        end
      end

      # Called by Shell for every line a command prints.
      def output(line)
        @log&.puts(line)
        clean = line.gsub(/\e\[[0-9;?]*[A-Za-z]/, "").strip
        return if clean.empty?

        @tail = clean
        @ui.say("#{@ui.prefix}  #{@ui.paint("│", :muted)} #{@ui.paint(clean, :muted)}") if @ui.verbose
      end

      # Mark the task as intentionally not done, with a reason ("up to date").
      def skip(reason)
        @skipped = reason
      end

      def elapsed = @ui.clock - @started

      # The most recent non-empty line of output, e.g. a command's summary.
      def last_line = @tail

      def finish
        stop_threads
        if @skipped
          render_final(@ui.paint(GLYPHS[:skip], :muted), @ui.paint(@skipped, :muted))
        else
          note = [@detail, @ui.duration(elapsed)].compact.join("  ")
          render_final(@ui.paint(GLYPHS[:ok], :ok, bold: true), @ui.paint(note, :muted))
        end
      end

      def fail(error)
        stop_threads
        what = error.is_a?(Interrupt) ? "interrupted" : "failed"
        render_final(@ui.paint(GLYPHS[:fail], :error, bold: true),
                     @ui.paint("#{what} after #{@ui.duration(elapsed)}", :error))
      end

      private

      def live? = @ui.tty? && !@ui.verbose

      def render_final(glyph, note)
        @ui.synchronize do
          @ui.raw("\r\e[2K\e[?25h") if live?
          @ui.raw("#{@ui.prefix}#{glyph} #{@ui.pad(@label)}#{note}\n")
          @ui.flush
        end
      end

      def spin
        frame = 0
        loop do
          render_live(SPINNER[frame % SPINNER.size])
          frame += 1
          sleep 0.08
        end
      end

      def render_live(glyph)
        head = "#{@ui.prefix}#{@ui.paint(glyph, :accent)} #{@ui.pad(@label)}"
        meta = [@detail, @ui.duration(elapsed)].compact.join("  ")
        line = "#{head}#{@ui.paint(meta, :muted)}"
        room = @ui.width - @ui.visible_length(line) - 4
        line += "  #{@ui.paint(@ui.truncate(@tail, room), :muted, dim: true)}" if @tail && room > 8
        @ui.synchronize do
          @ui.raw("\r\e[2K#{line}")
          @ui.flush
        end
      end

      def beat
        loop do
          sleep HEARTBEAT
          @ui.say "#{@ui.prefix}  #{@ui.paint("… #{@label}: still running (#{@ui.duration(elapsed)})", :muted)}"
        end
      end

      def stop_threads
        [@spinner, @heartbeat].compact.each do |thread|
          thread.kill
          thread.join
        end
        @spinner = @heartbeat = nil
      end
    end
  end
end
