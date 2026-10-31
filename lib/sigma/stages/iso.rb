# frozen_string_literal: true

require "erb"
require "fileutils"

module Sigma
  module Stages
    # Assembles the bootable ISO in out/: the kernels and initramfs collected
    # in cache/boot, the squashfs, and a GRUB menu with one entry per kernel.
    class Iso < Stage
      stage "iso", "bootable ISO", steps: %i[tree grub image]

      TEMPLATE = "image/grub.cfg.erb"

      # The boot menu theme ships in sigma-conf, so the live ISO and installed
      # systems (through /etc/default/grub) share one source of truth.
      THEME_DIR = "packages/sigma-conf/rootfs/usr/share/sigma/grub"

      Kernel = Struct.new(:flavor, :vmlinuz, :initramfs, :title, keyword_init: true)

      def tree = paths.iso_tree
      def theme_dir = File.join(paths.root, THEME_DIR)

      def inputs
        Fingerprint.of(config.name, config.dig("iso"), File.read(File.join(paths.root, TEMPLATE)),
                       Fingerprint.tree(theme_dir))
      end

      def outputs = [paths.iso]

      def clean(_items = nil)
        Mounts.remove_tree(tree)
        super
      end

      def check_prerequisites
        require_output(paths.squashfs, "squashfs")
        return unless kernels.empty?

        raise Error.new("no kernel in #{relative(paths.boot)}",
                        hint: "The profile must install a kernel (linux-sigma); rebuild with `sigma build rootfs..`.")
      end

      # Boot entries: the distribution's own kernel first, then any others.
      def kernels
        Dir[File.join(paths.boot, "vmlinuz-*")].map { |path| File.basename(path).delete_prefix("vmlinuz-") }
                                               .select { |flavor| File.exist?(File.join(paths.boot, "initramfs-#{flavor}")) }
                                               .sort_by { |flavor| [flavor == config.id ? 0 : 1, flavor] }
                                               .then { |flavors| entries(flavors) }
      end

      # Theme values from sigma-conf's grub.conf: plain KEY="value" lines.
      def theme
        File.readlines(File.join(theme_dir, "grub.conf"), chomp: true).each_with_object({}) do |line, vars|
          next unless (match = line.match(/\A([A-Z_][A-Z0-9_]*)=(?:"([^"]*)"|'([^']*)'|(\S*))\s*(?:#.*)?\z/))

          vars[match[1]] = match[2] || match[3] || match[4]
        end
      end

      protected

      def step_label(step) = { tree: "stage files", grub: "boot menu", image: "write image" }.fetch(step)
      def summary = "#{relative(paths.iso)} · #{ui.bytes(File.size(paths.iso))}"

      def step_tree(task)
        Mounts.remove_tree(tree)
        FileUtils.mkdir_p(File.join(tree, "boot", "grub"))
        shell.run(task, "cp", "-a", "#{paths.boot}/.", File.join(tree, "boot/"))
        squashfs = File.join(tree, "rootfs.squashfs")
        begin
          File.link(paths.squashfs, squashfs) # same filesystem: no 2 GB copy
        rescue SystemCallError
          FileUtils.cp(paths.squashfs, squashfs)
        end
        task.detail = ui.plural(kernels.size, "kernel")
      end

      def step_grub(task)
        grub = File.join(tree, "boot", "grub")
        FileUtils.mkdir_p(grub)
        FileUtils.cp(File.join(theme_dir, "wallpaper.png"), File.join(grub, "wallpaper.png"))
        File.write(File.join(grub, "grub.cfg"), render)
        task.detail = kernels.map(&:flavor).join(", ")
      end

      def step_image(task)
        FileUtils.mkdir_p(File.dirname(paths.iso))
        shell.run(task, "grub-mkrescue", tree, "-o", paths.iso, "-volid", config.fetch("iso.volume_id"), heavy: true)
        task.detail = ui.bytes(File.size(paths.iso))
      end

      private

      def entries(flavors)
        flavors.map do |flavor|
          Kernel.new(flavor: flavor, vmlinuz: "vmlinuz-#{flavor}", initramfs: "initramfs-#{flavor}",
                     title: flavors.size == 1 ? config.name : "#{config.name} (#{flavor})")
        end
      end

      def render
        values = { name: config.name, volume_id: config.fetch("iso.volume_id"), kernels: kernels, theme: theme,
                   cmdline: theme.fetch("GRUB_CMDLINE_LINUX_DEFAULT", "") }
        ERB.new(File.read(File.join(paths.root, TEMPLATE)), trim_mode: "-").result_with_hash(values)
      end
    end
  end
end
