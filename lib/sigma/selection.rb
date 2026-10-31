# frozen_string_literal: true

require "did_you_mean"

module Sigma
  # Parses what the user asked the pipeline to do.
  #
  #   (nothing)              every stage, incrementally (up-to-date ones skipped)
  #   rootfs                 one stage
  #   rootfs..  ..squashfs   open ranges
  #   rootfs..iso            closed range
  #   packages:a,b           part of a stage (packages, or steps)
  #
  # Arguments combine; the result is always in pipeline order, and a stage
  # asked for both whole and in part runs whole.
  class Selection
    Entry = Struct.new(:stage, :items) # items: nil means the whole stage

    attr_reader :entries

    def self.parse(args, stages) = new(args, stages)

    def initialize(args, stages)
      @stages = stages
      @incremental = args.empty?
      wanted = {}
      (args.empty? ? stages : []).each { |s| wanted[s] = nil }
      args.each { |arg| add(wanted, arg) }
      @entries = stages.filter_map { |s| Entry.new(s, wanted[s]) if wanted.key?(s) }
    end

    # True for a bare `sigma build`: skip stages that are up to date.
    def incremental? = @incremental

    def stages = entries.map(&:stage)

    private

    def add(wanted, arg)
      if arg.include?(":") && arg.include?("..")
        raise Error.new("`#{arg}` mixes a range with parts of a stage", hint: "Use separate arguments, e.g. `rootfs:configure squashfs..`.")
      end

      case arg
      when /\A([\w-]*)\.\.([\w-]*)\z/
        from = Regexp.last_match(1).empty? ? @stages.first : stage(Regexp.last_match(1))
        to = Regexp.last_match(2).empty? ? @stages.last : stage(Regexp.last_match(2))
        range = @stages[@stages.index(from)..@stages.index(to)]
        raise Error.new("`#{arg}` is backwards", hint: "Stages run #{@stages.join(" → ")}.") if range.nil? || range.empty?

        range.each { |s| wanted[s] = nil }
      when /\A([\w-]+):(.+)\z/
        name = stage(Regexp.last_match(1))
        items = Regexp.last_match(2).split(",").map(&:strip).reject(&:empty?)
        raise Error, "`#{arg}`: nothing after the colon" if items.empty?
        return if wanted.key?(name) && wanted[name].nil? # already whole

        wanted[name] = ((wanted[name] || []) + items).uniq
      when /\A[\w-]+\z/
        wanted[stage(arg)] = nil
      else
        raise Error.new("can't read selection `#{arg}`", hint: "See `sigma build --help`.")
      end
    end

    def stage(name)
      return name if @stages.include?(name)

      guess = DidYouMean::SpellChecker.new(dictionary: @stages).correct(name).first
      raise Error.new("no stage `#{name}`#{guess ? ", did you mean `#{guess}`?" : ""}",
                      hint: "Stages: #{@stages.join(" → ")}")
    end
  end
end
