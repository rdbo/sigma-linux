# frozen_string_literal: true

require "fileutils"

module Sigma
  # The staged build:  packages → rootfs → squashfs → iso
  class Pipeline
    STAGES = [Stages::Packages, Stages::Rootfs, Stages::Squashfs, Stages::Iso].freeze
    STAGE_NAMES = STAGES.map(&:stage_name).freeze

    STATUS_GLYPH = { fresh: [:ok, :ok], stale: [:warn, :warn], missing: [:skip, :muted] }.freeze

    attr_reader :state

    def initialize(context)
      @context = context
      @state = State.new(context.paths.state)
      @stages = STAGES.map { |klass| klass.new(context, self) }
    end

    def stage(name) = @stages.find { |s| s.name == name }
    def before(stage) = (index = @stages.index(stage)).positive? ? @stages[index - 1] : nil

    def profile
      @profile ||= Profile.new(File.join(@context.paths.root, "profiles"), config.profile)
    end

    # -- sigma build ------------------------------------------------------------

    def build(args, force: false, plan: false)
      selection = Selection.parse(args, STAGE_NAMES)
      selection.entries.each { |entry| stage(entry.stage).validate(entry.items) if entry.items }
      banner(plan ? "Plan" : "Build")
      return show_plan(selection, force) if plan

      started = ui.clock
      ran = selection.entries.filter_map do |entry|
        current = stage(entry.stage)
        if selection.incremental? && !force && current.fresh?
          ui.stage_skipped(current.name, "up to date")
          next
        end

        current.check_prerequisites
        ui.stage(current.name, current.description) { current.run(entry.items, force: force) }
        current
      end
      finish(ran, ui.clock - started)
    ensure
      Ownership.new(@context).restore
    end

    # -- sigma status -----------------------------------------------------------

    def status
      banner("Status")
      width = STAGE_NAMES.map(&:length).max + 2
      @stages.each do |current|
        state_now, reason = current.status
        glyph, role = STATUS_GLYPH.fetch(state_now)
        stamp = current.stamp
        built = stamp ? "built #{ago(stamp["finished_at"])} in #{ui.duration(stamp["duration"].to_f)}" : nil
        text = state_now == :fresh ? "up to date" : reason
        ui.say "  #{ui.paint(UI::GLYPHS[glyph], role)} #{ui.paint(current.name.ljust(width), :accent)}" \
               "#{ui.paint(text.ljust(22), role)}#{ui.paint(built.to_s, :muted)}"
      end
      ui.blank
      package_status
      artifact_status
    end

    # -- sigma clean ------------------------------------------------------------

    def clean(args, everything: false)
      banner("Clean")
      return clean_everything if everything

      selection = Selection.parse(args, STAGE_NAMES)
      selection.entries.reverse_each do |entry|
        current = stage(entry.stage)
        freed = current.outputs.sum { |path| disk_usage(path) }
        freed += disk_usage(@context.paths.repo) + disk_usage(File.dirname(@context.paths.staging)) if current.name == "packages" && entry.items.nil?
        current.clean(entry.items)
        what = entry.items ? "#{current.name}:#{entry.items.join(",")}" : current.name
        ui.line(:ok, what, freed.positive? ? "freed #{ui.bytes(freed)}" : "nothing to remove", role: :ok)
      end
      ui.blank
      ui.say "  #{ui.paint("Kept: downloads, ccache and the signing key (`sigma clean --everything` removes them).", :muted)}"
      ui.blank
    ensure
      Ownership.new(@context).restore
    end

    private

    def config = @context.config
    def ui = @context.ui

    def banner(action)
      runner = Docker.inside? ? "container" : "native"
      ui.banner("#{config.name} · #{action.downcase}",
                ["profile #{config.profile}", config.arch, "#{config.jobs} jobs", runner])
    end

    def show_plan(selection, force)
      width = STAGE_NAMES.map(&:length).max + 2
      selection.entries.each do |entry|
        current = stage(entry.stage)
        if selection.incremental? && !force && current.fresh?
          ui.say "  #{ui.paint(UI::GLYPHS[:skip], :muted)} #{ui.paint(current.name.ljust(width), :muted)}#{ui.paint("up to date, skipped", :muted)}"
        else
          ui.say "  #{ui.paint(UI::GLYPHS[:run], :accent)} #{ui.paint(current.name.ljust(width), :accent, bold: true)}#{current.plan(entry.items)}"
        end
      end
      ui.blank
    end

    def finish(ran, elapsed)
      if ran.empty?
        ui.box(["#{ui.paint(UI::GLYPHS[:ok], :ok, bold: true)} Everything is up to date."], role: :muted)
      else
        lines = ["#{ui.paint(UI::GLYPHS[:ok], :ok, bold: true)} #{ui.paint("Done in #{ui.duration(elapsed)}", :text, bold: true)}" \
                 "#{ui.paint("  #{ran.map(&:name).join(" → ")}", :muted)}"]
        iso = @context.paths.iso
        lines << "  #{relative(iso)}  #{ui.paint(ui.bytes(File.size(iso)), :muted)}" if ran.any? { |s| s.name == "iso" }
        lines << "  #{ui.paint("try it:", :muted)} ./sigma run" if ran.any? { |s| s.name == "iso" }
        ui.box(lines, role: :ok)
      end
      ui.blank
    end

    def package_status
      packages = stage("packages")
      list = packages.selected
      return if list.empty?

      ui.say "  #{ui.paint("packages", :accent, bold: true)} #{ui.paint("needed by profile #{config.profile}", :muted)}"
      list.each do |pkg|
        state_now, reason = packages.package_status(pkg)
        glyph, role = STATUS_GLYPH.fetch(state_now)
        ui.say "    #{ui.paint(UI::GLYPHS[glyph], role)} #{ui.pad("#{pkg.name} #{pkg.version}", 36)}#{ui.paint(reason || "up to date", role == :ok ? :muted : role)}"
      end
      others = packages.local.names - list.map(&:name)
      ui.say "    #{ui.paint("not in profile: #{others.join(", ")}", :muted)}" unless others.empty?
      ui.blank
    end

    def artifact_status
      iso = @context.paths.iso
      return unless File.exist?(iso)

      ui.say "  #{ui.paint("image", :accent, bold: true)}  #{relative(iso)} #{ui.paint("#{ui.bytes(File.size(iso))}, #{ago(File.mtime(iso).to_i)}", :muted)}"
      ui.blank
    end

    def clean_everything
      paths = @context.paths
      Mounts.under(paths.rootfs).empty? || stage("rootfs").clean
      [paths.cache, paths.out].each do |dir|
        freed = disk_usage(dir)
        Mounts.remove_tree(dir)
        ui.line(:ok, relative(dir), freed.positive? ? "freed #{ui.bytes(freed)}" : "nothing to remove", role: :ok)
      end
      ui.blank
    end

    def disk_usage(path)
      return 0 unless File.exist?(path)

      @context.shell.capture("du", "-sk", path).split.first.to_i * 1024
    rescue CommandFailed
      0
    end

    def ago(epoch)
      seconds = Time.now.to_i - epoch.to_i
      return "just now" if seconds < 60
      return "#{seconds / 60}m ago" if seconds < 3600
      return "#{seconds / 3600}h ago" if seconds < 86_400

      "#{seconds / 86_400}d ago"
    end

    def relative(path) = path.to_s.delete_prefix("#{@context.paths.root}/")
  end
end
