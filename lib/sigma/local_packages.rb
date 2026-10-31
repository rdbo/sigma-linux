# frozen_string_literal: true

module Sigma
  # The recipes under packages/, and which of them a build needs.
  #
  # Local packages are built on demand: a profile pulls in the ones it names
  # (directly, through a subpackage like linux-sigma-dev, or through a provided
  # name like initramfs-generator) plus their local dependencies. Recipes no
  # profile uses cost nothing, but can still be built by name.
  class LocalPackages
    include Enumerable

    def initialize(dir, shell:, carch:)
      @dir = dir
      @shell = shell
      @carch = carch
    end

    def each(&) = all.each(&)

    def all
      @all ||= Dir[File.join(@dir, "*", "APKBUILD")].sort.map do |path|
        Apkbuild.read(File.dirname(path), shell: @shell, carch: @carch)
      end
    end

    def names = all.map(&:name)

    # Finds the recipe answering to +name+ (a pkgname, subpackage or provide).
    def [](name) = index[name]

    # Local packages the given profile packages need, in build order.
    def for_profile(packages)
      seeds = packages.filter_map { |p| self[p] }
      order(closure(seeds) { |pkg| pkg.depends + pkg.makedepends + pkg.checkdepends })
    end

    # The named packages plus what they need to *build*, in build order.
    def for_names(requested)
      seeds = requested.map do |name|
        self[name] or raise Error.new("no local package `#{name}`",
                                      hint: "Local packages: #{names.join(", ")}")
      end
      order(closure(seeds) { |pkg| pkg.makedepends + pkg.checkdepends })
    end

    private

    def index
      @index ||= all.each_with_object({}) do |pkg, map|
        pkg.aliases.each { |alias_name| map[alias_name] ||= pkg }
      end
    end

    def closure(seeds)
      seen = {}
      queue = seeds.dup
      until queue.empty?
        pkg = queue.shift
        next if seen[pkg.name]

        seen[pkg.name] = pkg
        yield(pkg).each { |dep| (local = self[dep]) && queue << local }
      end
      seen.values
    end

    # Topological order over local dependencies; ties keep alphabetical order
    # so builds are predictable.
    def order(packages)
      members = packages.to_h { |p| [p.name, p] }
      sorted = []
      state = {}
      visit = lambda do |pkg, path|
        return if state[pkg.name] == :done
        raise Error, "dependency cycle between local packages: #{(path + [pkg.name]).join(" → ")}" if state[pkg.name] == :visiting

        state[pkg.name] = :visiting
        (pkg.depends + pkg.makedepends + pkg.checkdepends).each do |dep|
          local = self[dep]
          visit.call(local, path + [pkg.name]) if local && members[local.name] && local != pkg
        end
        state[pkg.name] = :done
        sorted << pkg
      end
      members.values.sort_by(&:name).each { |pkg| visit.call(pkg, []) }
      sorted
    end
  end
end
