# frozen_string_literal: true

require_relative "test_helper"

class IsoTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @context = Sigma::Context.new(config("paths.cache" => @dir), quiet_ui)
    pipeline = Sigma::Pipeline.new(@context)
    @iso = pipeline.stage("iso")
    FileUtils.mkdir_p(@context.paths.boot)
  end

  def teardown = FileUtils.rm_rf(@dir)

  def boot(*files) = files.each { |f| FileUtils.touch(File.join(@context.paths.boot, f)) }

  # The menu the old make_iso.sh heredoc produced, verbatim.
  OLD_MENU = <<~'CFG'
    set timeout=5

    insmod all_video
    loadfont /boot/grub/fonts/unicode.pf2

    insmod gfxterm
    set gfxmode=640x480
    terminal_output gfxterm

    insmod png
    background_image /boot/grub/wallpaper.png

    menuentry "Sigma Linux" {
    	echo "Loading vmlinuz..."
    	linux /boot/vmlinuz-sigma root=LABEL=sigma-linux-cdrom rootfstype=iso9660 rd.live=/rootfs.squashfs vt.color=0x0B vt.default_red=0x10,0xaa,0x00,0xaa,0x00,0xaa,0x00,0xaa,0x55,0xff,0x55,0xff,0x55,0xff,0x00,0xff vt.default_grn=0x1a,0x00,0xaa,0x55,0x00,0x00,0xaa,0xaa,0x55,0x55,0xff,0xff,0x55,0x55,0xff,0xff vt.default_blu=0x20,0x00,0x00,0x00,0xaa,0xaa,0xaa,0xaa,0x55,0x55,0x55,0x55,0xff,0xff,0xc8,0xff splash
    	echo "Loading initrd..."
    	initrd /boot/initramfs-sigma
    }
  CFG

  def test_single_kernel_menu_matches_the_old_one
    boot("vmlinuz-sigma", "initramfs-sigma", "System.map-7.3.1-0-sigma")
    assert_equal OLD_MENU, @iso.send(:render)
  end

  def test_one_entry_per_kernel_own_kernel_first
    boot("vmlinuz-stable", "initramfs-stable", "vmlinuz-sigma", "initramfs-sigma", "vmlinuz-noinitrd")
    kernels = @iso.kernels
    assert_equal %w[sigma stable], kernels.map(&:flavor)
    assert_equal ["Sigma Linux (sigma)", "Sigma Linux (stable)"], kernels.map(&:title)
    assert_equal 2, @iso.send(:render).scan("menuentry").size
  end

  def test_theme_parses_the_shared_file
    theme = @iso.theme
    assert_equal "640x480", theme["GRUB_GFXMODE"]
    assert_equal "Sigma Linux", theme["GRUB_DISTRIBUTOR"]
    assert theme["GRUB_CMDLINE_LINUX_DEFAULT"].start_with?("vt.color=0x0B ")
  end
end
