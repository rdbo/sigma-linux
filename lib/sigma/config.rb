# frozen_string_literal: true

require "yaml"
require "etc"

module Sigma
  # Build configuration, layered (later wins):
  #
  #   config/sigma.yml    committed defaults
  #   config/local.yml    personal overrides (git-ignored)
  #   --set key=value     one-off overrides from the command line
  class Config
    DEFAULTS = "config/sigma.yml"
    LOCAL = "config/local.yml"

    # Where everything lives. Intermediate state goes under cache/ (always safe
    # to delete); finished artifacts go under out/.
    Paths = Struct.new(
      :root, :cache, :out,
      :state, :logs, :keys, :ccache,
      :sources,      # abuild source downloads (SRCDEST)
      :apk_cache,    # apk package downloads for the image
      :staging,      # abuild working copies of packages/<name>
      :repo,         # local repository (abuild REPODEST)
      :rootfs, :boot, :iso_tree, :squashfs, :iso,
      keyword_init: true
    )

    REPO_NAME = "sigma" # abuild names the repo after the staging dir's parent

    attr_reader :root, :data, :sources

    def self.load(root, overrides: [])
      new(root, overrides)
    end

    def initialize(root, overrides)
      @root = root
      @sources = []
      @data = {}
      [DEFAULTS, LOCAL].each do |relative|
        path = File.join(root, relative)
        next unless File.exist?(path)

        @data = deep_merge(@data, read_yaml(path))
        @sources << relative
      end
      raise Error.new("missing #{DEFAULTS}", hint: "Run sigma from the repository checkout.") if @sources.empty?

      overrides.each { |assignment| apply_override(assignment) }
      @sources << "--set" unless overrides.empty?
    end

    # dig("squashfs", "compression") or dig("squashfs.compression")
    def dig(*keys)
      keys = keys.flat_map { |k| k.to_s.split(".") }
      keys.reduce(@data) { |node, key| node.is_a?(Hash) ? node[key] : nil }
    end

    def fetch(path)
      value = dig(path)
      raise Error.new("config: `#{path}` is not set", hint: "Add it to #{LOCAL} or pass --set #{path}=…") if value.nil?

      value
    end

    def name = fetch("name")
    def id = fetch("id")
    def arch = fetch("arch")
    def profile = fetch("profile")
    def builder = fetch("packages.builder")

    # `auto` leaves headroom so a build can't starve the machine: one core
    # stays free, and each job gets ~1.5 GiB of RAM (roughly what one kernel
    # compiler process peaks at). Using every core once made a build host
    # unresponsive.
    def jobs
      value = dig("jobs")
      return Integer(value) unless value.nil? || value == "auto"

      by_cpu = Etc.nprocessors - 1
      by_memory = (memory_gib / GIB_PER_JOB).floor
      [by_cpu, by_memory].min.clamp(1, Etc.nprocessors)
    end

    GIB_PER_JOB = 1.5

    def memory_gib
      File.read("/proc/meminfo")[/^MemTotal:\s+(\d+) kB/, 1].to_i / 1024.0 / 1024
    rescue SystemCallError
      GIB_PER_JOB * 2
    end

    def paths
      @paths ||= begin
        cache = File.expand_path(dig("paths.cache") || "cache", root)
        out = File.expand_path(dig("paths.out") || "out", root)
        Paths.new(
          root: root, cache: cache, out: out,
          state: File.join(cache, "state"),
          logs: File.join(cache, "logs"),
          keys: File.join(cache, "keys"),
          ccache: File.join(cache, "ccache"),
          sources: File.join(cache, "downloads", "sources"),
          apk_cache: File.join(cache, "downloads", "apk"),
          staging: File.join(cache, "build", REPO_NAME),
          repo: File.join(cache, "repo"),
          rootfs: File.join(cache, "rootfs"),
          boot: File.join(cache, "boot"),
          iso_tree: File.join(cache, "iso"),
          squashfs: File.join(cache, "rootfs.squashfs"),
          iso: File.join(out, "#{id}-linux.iso")
        )
      end
    end

    # The local repository as apk sees it (REPODEST/<repo>).
    def repo_dir = File.join(paths.repo, REPO_NAME)

    # Flattened "a.b.c" => value pairs, for display.
    def flatten(node = @data, prefix = nil)
      node.flat_map do |key, value|
        path = [prefix, key].compact.join(".")
        value.is_a?(Hash) ? flatten(value, path) : [[path, value]]
      end
    end

    private

    def read_yaml(path)
      YAML.safe_load_file(path) || {}
    rescue Psych::SyntaxError => e
      raise Error, "#{path}: #{e.message}"
    end

    def apply_override(assignment)
      key, value = assignment.split("=", 2)
      raise Error.new("bad --set `#{assignment}`", hint: "Use --set key.path=value") if value.nil? || key.empty?

      *parents, leaf = key.split(".")
      node = parents.reduce(@data) { |n, k| n[k] = n[k].is_a?(Hash) ? n[k] : {} }
      node[leaf] = YAML.safe_load(value)
    rescue Psych::SyntaxError
      node[leaf] = value
    end

    def deep_merge(base, other)
      base.merge(other) do |_, a, b|
        a.is_a?(Hash) && b.is_a?(Hash) ? deep_merge(a, b) : b
      end
    end
  end
end
