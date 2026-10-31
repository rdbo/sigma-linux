# frozen_string_literal: true

require "optparse"

module Sigma
  # Command-line front end: parses arguments, decides whether to hop into the
  # build container, and renders errors.
  class CLI
    # Commands that touch the build environment run inside the container
    # unless we are already there or --native is given.
    CONTAINERIZED = %w[build pkg clean shell].freeze

    COMMANDS = {
      "build" => "Run the pipeline, skipping stages that are up to date",
      "pkg" => "Build local packages (same as build packages:NAME,…)",
      "status" => "Show what is built and what is stale",
      "clean" => "Delete stage outputs (every stage by default)",
      "shell" => "Open a shell in the build container",
      "run" => "Boot the ISO (or an installed disk) in QEMU",
      "config" => "Print the effective configuration"
    }.freeze

    def self.start(argv) = new.start(argv)

    def initialize
      @options = { verbose: false, native: false, overrides: [], color: nil, force: false, plan: false }
    end

    def start(argv)
      @original_argv = argv.dup
      argv = argv.dup
      command = argv.first&.start_with?("-") ? nil : argv.shift
      parser = option_parser(command)
      args = parser.parse(argv)
      @ui = UI.new(verbose: @options[:verbose], color: @options[:color])

      return help(parser) if command.nil? || command == "help"
      raise Error.new("unknown command `#{command}`", hint: "See `sigma --help`.") unless COMMANDS.key?(command)

      @config = Config.load(ROOT, overrides: @options[:overrides])
      return Docker.new(@config, @ui).dispatch(@original_argv) if containerize?(command)

      public_send("cmd_#{command}", args)
      0
    rescue OptionParser::ParseError => e
      render_error(Error.new(e.message, hint: "See `sigma #{command} --help`."))
    rescue CommandFailed, Error => e
      render_error(e)
    rescue Interrupt
      ui = @ui || UI.new
      ui.blank
      ui.say "  #{ui.paint("Interrupted.", :warn)}"
      130
    end

    # -- commands ---------------------------------------------------------------

    def cmd_build(selections)
      Pipeline.new(context).build(selections, force: @options[:force], plan: @options[:plan])
    end

    def cmd_pkg(names)
      raise Error.new("which packages?", hint: "e.g. `sigma pkg linux-sigma`") if names.empty?

      cmd_build(["packages:#{names.join(",")}"])
    end

    def cmd_status(_args)
      Pipeline.new(context).status
    end

    def cmd_clean(selections)
      Pipeline.new(context).clean(selections, everything: @options[:everything])
    end

    def cmd_shell(_args)
      # Only reached with --native or inside the container already.
      exec(ENV.fetch("SHELL", "/bin/sh"))
    end

    def cmd_run(extra)
      Qemu.new(@config, @ui).boot(uefi: @options[:uefi], disk: @options[:disk], iso: @options.fetch(:iso, true), extra: extra)
    end

    def cmd_config(keys)
      if keys.empty?
        @ui.banner("Configuration", @config.sources)
        @ui.table(@config.flatten.map { |k, v| [k, format_value(v)] })
        @ui.blank
      else
        keys.each { |key| @ui.say format_value(@config.fetch(key)) }
      end
    end

    private

    def context
      @context ||= Context.new(@config, @ui)
    end

    # --plan only reads files, so it never needs the container.
    def containerize?(command)
      CONTAINERIZED.include?(command) && !@options[:native] && !@options[:plan] && !Docker.inside?
    end

    def format_value(value)
      case value
      when Array then value.join(" ")
      when nil then @ui.paint("(unset)", :muted)
      else value.to_s
      end
    end

    def option_parser(command)
      OptionParser.new do |o|
        o.banner = command ? "Usage: sigma #{command} #{usage_args(command)}" : "Usage: sigma <command> [options]"
        o.on("-v", "--verbose", "Stream command output instead of a live summary") { @options[:verbose] = true }
        o.on("-s", "--set KEY=VALUE", "Override a config value (repeatable)") { |v| @options[:overrides] << v }
        o.on("--native", "Run here instead of in the build container") { @options[:native] = true }
        o.on("--no-color", "Disable colour") { @options[:color] = false }
        case command
        when "build", "pkg"
          o.on("-f", "--force", "Rebuild even what is up to date") { @options[:force] = true }
          o.on("--plan", "Show what would run, and stop") { @options[:plan] = true }
        when "clean"
          o.on("--everything", "Also delete downloads, ccache, signing keys and out/") { @options[:everything] = true }
        when "run"
          o.on("--uefi", "Boot with UEFI firmware (OVMF) instead of BIOS") { @options[:uefi] = true }
          o.on("--disk FILE", "Attach a virtual disk (qcow2, created if missing)") { |f| @options[:disk] = File.expand_path(f) }
          o.on("--no-iso", "Boot only the disk (an installed system; needs --uefi)") { @options[:iso] = false }
        end
        o.on("-h", "--help", "Show this help") do
          help(o, command)
          exit 0
        end
      end
    end

    def usage_args(command)
      {
        "build" => "[SELECTION…] [options]", "pkg" => "NAME… [options]", "clean" => "[SELECTION…] [options]",
        "run" => "[options] [-- QEMU ARGS]", "config" => "[KEY…]"
      }.fetch(command, "[options]")
    end

    def help(parser, command = nil)
      ui = @ui || UI.new
      if command
        ui.say parser.help
        ui.blank
        selection_help(ui) if %w[build clean].include?(command)
        return 0
      end

      ui.banner("Sigma Linux builder")
      ui.say "  #{ui.paint("Usage", :accent, bold: true)}  sigma <command> [options]"
      ui.blank
      width = COMMANDS.keys.map(&:length).max
      COMMANDS.each { |name, text| ui.say "    #{ui.paint(name.ljust(width), :text, bold: true)}  #{ui.paint(text, :muted)}" }
      ui.blank
      selection_help(ui)
      ui.say "  #{ui.paint("Options", :accent, bold: true)}"
      parser.summarize { |line| ui.say "  #{line}" }
      ui.blank
      ui.say "  #{ui.paint("`sigma <command> --help` for command options.", :muted)}"
      ui.blank
      0
    end

    def selection_help(ui)
      ui.say "  #{ui.paint("Selections", :accent, bold: true)}  #{ui.paint("stages: #{Pipeline::STAGE_NAMES.join(" → ")}", :muted)}"
      [
        ["rootfs", "one stage (always runs)"],
        ["rootfs..", "rootfs and every stage after it"],
        ["..squashfs", "every stage up to squashfs"],
        ["packages:linux-sigma,initrdbo", "part of a stage: packages…"],
        ["rootfs:configure", "…or steps"]
      ].each { |sel, text| ui.say "    #{sel.ljust(30)}  #{ui.paint(text, :muted)}" }
      ui.say "    #{ui.paint("(none: the whole pipeline, skipping what is up to date)", :muted)}"
      ui.blank
    end

    def render_error(error)
      ui = @ui || UI.new
      room = ui.width - 12
      lines = ui.wrap(error.message, room).map { |l| ui.paint(l, :text, bold: true) }
      if error.is_a?(CommandFailed)
        unless error.tail.empty?
          lines << ""
          lines << ui.paint("first error in the output:", :text) if error.first_error
          lines.concat(error.excerpt.map { |l| ui.paint(without_build_tree(l), :muted) })
        end
        lines << "" << "#{ui.paint("log", :muted)}  #{relative(error.log_path)}" if error.log_path
      end
      if error.hint
        hint = ui.wrap(error.hint, room - 5)
        lines << "" << "#{ui.paint("hint", :accent)} #{hint.first}"
        lines.concat(hint.drop(1).map { |l| "     #{l}" })
      end
      ui.blank
      ui.box(lines, title: ui.paint("error", :error, bold: true), role: :error)
      ui.blank
      1
    end

    # Compiler messages name files by their full path in abuild's build tree
    # (cache/build/sigma/<package>/src/...); without that prefix the message
    # itself fits in the box.
    def without_build_tree(line)
      return line unless @config

      line.gsub(%r{#{Regexp.escape(@config.paths.staging)}/[^/\s]+/src/}, "")
    end

    def relative(path)
      path.to_s.delete_prefix("#{ROOT}/")
    end
  end
end
