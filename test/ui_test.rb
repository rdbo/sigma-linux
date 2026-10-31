# frozen_string_literal: true

require_relative "test_helper"

class UITest < Minitest::Test
  def test_durations
    ui = quiet_ui
    assert_equal "0.4s", ui.duration(0.4)
    assert_equal "42s", ui.duration(42)
    assert_equal "4m 05s", ui.duration(245)
    assert_equal "1h 03m", ui.duration(3780)
  end

  def test_counts
    ui = quiet_ui
    assert_equal "950", ui.count(950)
    assert_equal "18.2k", ui.count(18_193)
    assert_equal "1.0M", ui.count(999_999)
  end

  def test_wrap_and_truncate
    ui = quiet_ui
    assert_equal ["aaa bbb", "ccc"], ui.wrap("aaa bbb ccc", 8)
    assert_equal "abcd…", ui.truncate("abcdefgh", 5)
  end

  def test_no_color_when_not_a_tty
    out = StringIO.new
    ui = Sigma::UI.new(out: out)
    ui.say ui.paint("x", :accent, bold: true)
    assert_equal "x\n", out.string
  end
end
