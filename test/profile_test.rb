# frozen_string_literal: true

require_relative "test_helper"

class ProfileTest < Minitest::Test
  def with_profiles(files)
    Dir.mktmpdir do |dir|
      files.each { |name, body| File.write(File.join(dir, "#{name}.list"), body) }
      yield dir
    end
  end

  def test_includes_removals_and_globs_apply_in_order
    with_profiles("base" => "a b # trailing comment\nfw-x fw-y\n",
                  "top" => "@include base\n-fw-*\nfw\nc\n-a\na\n") do |dir|
      assert_equal %w[b fw c a], Sigma::Profile.new(dir, "top").packages
    end
  end

  def test_cycles_and_unknown_directives_are_errors
    with_profiles("a" => "@include b\n", "b" => "@include a\n", "c" => "@require x\n") do |dir|
      assert_match(/cycle/, assert_raises(Sigma::Error) { Sigma::Profile.new(dir, "a") }.message)
      assert_match(/@require/, assert_raises(Sigma::Error) { Sigma::Profile.new(dir, "c") }.message)
      assert_raises(Sigma::Error) { Sigma::Profile.new(dir, "missing") }
    end
  end

  def test_shipped_profiles_layer
    dir = File.join(Sigma::ROOT, "profiles")
    minimal, standard, full = %w[minimal standard full].map { |n| Sigma::Profile.new(dir, n).packages }
    assert_empty minimal - standard, "minimal ⊂ standard"
    assert_includes full, "linux-firmware"
    refute full.any? { |p| p.start_with?("linux-firmware-") }, "full swaps the firmware subset for linux-firmware"
    %w[linux-sigma sigma-conf initrdbo].each { |p| assert_includes minimal, p }
  end
end
