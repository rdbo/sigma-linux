# frozen_string_literal: true

require "open3"

module Sigma
  # Boots the built ISO in a VM, for a quick look at the result.
  class Qemu
    OVMF = %w[
      /usr/share/OVMF/OVMF.fd
      /usr/share/ovmf/OVMF.fd
      /usr/share/ovmf/x64/OVMF.fd
      /usr/share/edk2/x64/OVMF.fd
      /usr/share/qemu/OVMF.fd
    ].freeze

    def initialize(config, ui)
      @config = config
      @ui = ui
    end

    DISK_SIZE = "20G"

    # Boots the ISO, optionally with a virtual disk attached (created on first
    # use) to try the installer on. With iso: false only the disk boots,
    # which needs UEFI: setup-sigma installs GRUB for EFI only.
    def boot(uefi: false, disk: nil, iso: true, extra: [])
      raise Error.new("nothing to boot", hint: "--no-iso needs --disk.") unless iso || disk
      raise Error.new("an installed system boots with UEFI only", hint: "Add --uefi.") if !iso && !uefi

      cmd = ["qemu-system-#{@config.arch}", "-smp", "4", "-m", "2048"]
      if iso
        image = @config.paths.iso
        raise Error.new("no ISO at #{relative(image)}", hint: "Build one with `sigma build`.") unless File.exist?(image)

        cmd += ["-cdrom", image]
      end
      if disk
        create_disk(disk)
        # NVMe, like real hardware: virtio_blk isn't in the initramfs's
        # module list, so an installed system on a virtio disk can't find /.
        cmd += ["-drive", "file=#{disk},format=qcow2,if=none,id=sigmadisk", "-device", "nvme,serial=sigma,drive=sigmadisk"]
      end
      cmd += ["-enable-kvm"] if File.writable?("/dev/kvm")
      cmd += ["-bios", firmware] if uefi
      cmd += extra

      @ui.banner("Booting #{iso ? File.basename(@config.paths.iso) : File.basename(disk)}",
                 [uefi ? "UEFI" : "BIOS", File.writable?("/dev/kvm") ? "KVM" : "no KVM (slow)",
                  disk && iso ? "disk #{relative(disk)}" : nil].compact)
      exec(*cmd)
    rescue Errno::ENOENT => e
      raise Error.new("#{e.message.split(" - ").last} not found", hint: "Install QEMU on this machine (apk add qemu-system-#{@config.arch} qemu-img).")
    end

    private

    def firmware
      OVMF.find { |path| File.exist?(path) } or
        raise Error.new("no UEFI firmware found", hint: "Install OVMF (apk add ovmf), looked in: #{OVMF.join(", ")}")
    end

    # A sparse qcow2 image: it only takes the space the guest writes.
    def create_disk(path)
      return if File.exist?(path)

      out, status = Open3.capture2e("qemu-img", "create", "-f", "qcow2", path, DISK_SIZE)
      raise Error, "could not create #{path}: #{out.strip}" unless status.success?

      @ui.say "  #{@ui.paint("created #{relative(path)} (#{DISK_SIZE}, sparse)", :muted)}"
    end

    def relative(path) = path.delete_prefix("#{@config.root}/")
  end
end
