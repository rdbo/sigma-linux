# frozen_string_literal: true

module Sigma
  # A package profile: profiles/<name>.list.
  #
  #   # comment            ignored, also after packages on a line
  #   foo bar              packages to install
  #   @include minimal     everything another profile resolves to, in place
  #   -foo -linux-fw-*     remove packages added so far (globs allowed)
  #
  # Lines are applied in order, so a removal only affects what came before it.
  class Profile
    attr_reader :name, :packages, :files

    def self.names(dir)
      Dir[File.join(dir, "*.list")].map { |f| File.basename(f, ".list") }.sort
    end

    def initialize(dir, name)
      @dir = dir
      @name = name
      @files = []
      @packages = resolve(name, [])
    end

    def include?(package) = @packages.include?(package)

    private

    def resolve(name, stack)
      path = File.join(@dir, "#{name}.list")
      unless File.exist?(path)
        raise Error.new("no profile `#{name}`",
                        hint: "Profiles: #{Profile.names(@dir).join(", ")} (#{relative(@dir)}/<name>.list)")
      end
      raise Error, "profile include cycle: #{(stack + [name]).join(" → ")}" if stack.include?(name)

      @files << path
      File.readlines(path, chomp: true).each_with_index.reduce([]) do |packages, (line, index)|
        line = line.sub(/#.*/, "").strip
        next packages if line.empty?

        if line.start_with?("@")
          directive(packages, line, stack + [name], "#{relative(path)}:#{index + 1}")
        else
          line.split.reduce(packages) do |acc, token|
            token.start_with?("-") ? acc.reject { |p| File.fnmatch?(token[1..], p) } : acc | [token]
          end
        end
      end
    end

    def directive(packages, line, stack, where)
      keyword, argument, *rest = line.split
      unless keyword == "@include" && argument && rest.empty?
        raise Error.new("#{where}: don't understand `#{line}`", hint: "The only directive is `@include <profile>`.")
      end

      packages | resolve(argument, stack)
    end

    def relative(path) = path.delete_prefix("#{ROOT}/")
  end
end
