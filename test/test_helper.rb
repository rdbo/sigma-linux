# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/sigma"

module TestHelpers
  def config(**overrides)
    sets = overrides.map { |k, v| "#{k}=#{v}" }
    Sigma::Config.load(Sigma::ROOT, overrides: sets)
  end

  def quiet_ui = Sigma::UI.new(out: StringIO.new, color: false)
end

Minitest::Test.include(TestHelpers)
