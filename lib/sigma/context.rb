# frozen_string_literal: true

require "etc"
require "fileutils"

module Sigma
  # What a single invocation shares across stages: configuration, the UI, the
  # command runner, and this run's log directory.
  class Context
    KEEP_LOGS = 10 # runs

    attr_reader :config, :ui, :shell, :run_id

    def initialize(config, ui)
      @config = config
      @ui = ui
      @shell = Shell.new(builder: config.builder)
      @run_id = Time.now.strftime("%Y-%m-%d_%H%M%S")
    end

    def paths = config.paths

    # Opens the log for one task: cache/logs/<run>/<stage>/<name>.log, and
    # points cache/logs/latest at this run.
    def log(stage, name)
      dir = File.join(paths.logs, run_id, stage.to_s)
      FileUtils.mkdir_p(dir)
      link_latest
      File.open(File.join(dir, "#{name.to_s.gsub(/[^\w.-]+/, "_")}.log"), "a").tap { |f| f.sync = true }
    end

    # Runs a UI task with its own log, closing the log afterwards.
    def task(stage, name, label: name, &block)
      log = log(stage, name)
      ui.task(label, log: log, &block)
    ensure
      log&.close
    end

    # As root, the unprivileged builder must own what abuild writes to.
    def give_to_builder(path, recursive: false)
      return unless shell.root?

      user = Etc.getpwnam(config.builder)
      recursive ? FileUtils.chown_R(user.uid, user.gid, path) : File.chown(user.uid, user.gid, path)
    rescue ArgumentError
      raise Error.new("build user `#{config.builder}` doesn't exist",
                      hint: "The container creates it; natively, set packages.builder to an abuild user.")
    end

    private

    # On the first log of a run: point cache/logs/latest here and drop the
    # logs of all but the last KEEP_LOGS runs.
    def link_latest
      return if @linked

      latest = File.join(paths.logs, "latest")
      FileUtils.rm_f(latest)
      File.symlink(run_id, latest)
      runs = Dir.children(paths.logs).reject { |d| d == "latest" }.sort
      runs.first([runs.size - KEEP_LOGS, 0].max).each { |old| FileUtils.rm_rf(File.join(paths.logs, old)) }
      @linked = true
    end
  end
end
