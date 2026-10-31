# frozen_string_literal: true

require "fileutils"

module Sigma
  module Stages
    # Builds the root filesystem in cache/rootfs/, and collects what packages
    # install into /boot (kernel, initramfs) in cache/boot/.
    #
    # Every run starts from an empty root: the configure step isn't idempotent
    # (users, services), and with the apk download cache a fresh install takes
    # about a minute.
    class Rootfs < Stage
      stage "rootfs", "root filesystem", steps: %i[prepare install configure]

      # Alpine's grub trigger regenerates grub.cfg whenever a kernel is
      # installed. Inside the image build that's wasted work at best, so it is
      # disabled while we build, and the guard is removed before shipping so
      # installed systems keep regenerating their (themed) config.
      GRUB_GUARD = "etc/update-grub.conf"

      def root = paths.rootfs
      def profile = @pipeline.profile
      def overlay = File.expand_path(config.fetch("rootfs.overlay"), paths.root)
      def repositories = File.expand_path(config.fetch("rootfs.repositories"), paths.root)

      def inputs
        Fingerprint.of(profile.packages, profile.files.map { |f| File.read(f) }, Fingerprint.tree(overlay),
                       File.read(repositories), config.dig("rootfs"), config.arch, config.id)
      end

      def outputs = [root, paths.boot]

      def plan(items)
        selected = (items || steps).map(&:to_s)
        detail = selected.include?("install") ? " (#{profile.packages.size} packages, profile #{profile.name})" : ""
        "#{selected.join(", ")}#{detail}"
      end

      def check_prerequisites
        return if @pipeline.stage("packages").selected.empty?

        require_output(File.join(config.repo_dir, config.arch, "APKINDEX.tar.gz"), "packages")
      end

      def run(items, force: false)
        unless shell.root?
          raise Error.new("building the root filesystem needs root (mounts, chroot)",
                          hint: "Run it in the container (drop --native), or as root.")
        end
        if items && !items.include?("prepare") && !File.directory?(File.join(root, "etc"))
          raise Error.new("there is no root filesystem to #{items.join(" and ")}", hint: "Run the whole stage: `sigma build rootfs`.")
        end

        super
      end

      def clean(_items = nil)
        unless Mounts.under(root).empty?
          context.task(name, "unmount", label: "unmount leftovers") { |t| Mounts.release(shell, t, root) }
        end
        super
      end

      protected

      def step_label(step)
        { prepare: "prepare", install: "install #{profile.packages.size} packages", configure: "configure" }.fetch(step)
      end

      def summary = "#{ui.bytes(disk_usage(root))} root"

      def step_prepare(task)
        Mounts.release(shell, task, root) # leftovers of an interrupted run
        [root, paths.boot].each { |dir| Mounts.remove_tree(dir) }
        FileUtils.mkdir_p([File.join(root, "etc/apk/keys"), paths.boot])

        # Trust Alpine's keys (from this machine) and our repository's key, so
        # every package is verified: no --allow-untrusted.
        keys = Dir["/etc/apk/keys/*.pub"] + [Signing.new(context).public_key].compact
        FileUtils.cp(keys, File.join(root, "etc/apk/keys"))
        File.write(File.join(root, GRUB_GUARD), "disable_trigger=1\n")

        # Overlay files go in before packages too, so install-time triggers
        # see them (the initramfs generator reads /etc/modules).
        copy_overlay
        task.detail = "#{ui.plural(keys.size, "trusted key")}"
      end

      def step_install(task)
        FileUtils.mkdir_p(paths.apk_cache)
        chroot_mounts(task) do
          shell.run(task, "apk", "add", "--root", root, "--initdb", "--arch", config.arch, "--update-cache",
                    "--repositories-file", repositories, "--repository", config.repo_dir,
                    "--cache-dir", paths.apk_cache, *profile.packages)
        end
        task.detail = task.last_line.to_s[/\AOK: (.*)/, 1]
      end

      def step_configure(task)
        chroot_mounts(task) do
          copy_overlay(drop_apk_new: true)
          File.write(File.join(root, "etc/hostname"), "#{config.id}\n")
          FileUtils.cp(repositories, File.join(root, "etc/apk/repositories"))

          config.fetch("rootfs.skel_dirs").each { |dir| FileUtils.mkdir_p(File.join(root, "etc/skel", dir)) }
          # Root gets a desktop-ready home too (logging in as root on the live ISO).
          shell.run(task, "cp", "-a", "#{root}/etc/skel/.", "#{root}/root/")

          enable_services(task)
          create_user(task)

          # https://alpinelinux.org/posts/2025-10-01-usr-merge.html
          shell.run(task, "chroot", root, "merge-usr")
          FileUtils.rm_f(File.join(root, GRUB_GUARD))
        end
      end

      private

      def enable_services(task)
        config.fetch("rootfs.services").each do |level, services|
          services.each { |service| shell.run(task, "chroot", root, "rc-update", "add", service, level) }
        end
      end

      def create_user(task)
        user = config.fetch("rootfs.user")
        shell.run(task, "useradd", "-R", root, "-s", user.fetch("shell"), "-m",
                  "-G", user.fetch("groups").join(","), user.fetch("name"))
        shell.run(task, "chroot", root, "chpasswd", input: "#{user.fetch("name")}:#{user.fetch("password")}\n")
      end

      # Packages write to /dev and /proc while installing (e.g. /dev/null), and
      # the kernel and initramfs land in /boot, which is cache/boot here.
      def chroot_mounts(task)
        Mounts.bind(shell, task, "/dev", File.join(root, "dev"))
        Mounts.bind(shell, task, "/proc", File.join(root, "proc"))
        Mounts.bind(shell, task, paths.boot, File.join(root, "boot"))
        yield
      ensure
        begin
          Mounts.release(shell, task, root)
        rescue Error => e
          ui.warn(e.message)
        end
      end

      # Files are written by us (so owned by root in the image, whatever owns
      # the checkout) with their modes kept. With drop_apk_new, the .apk-new
      # copies apk left next to them while installing are removed: the
      # overlay wins.
      def copy_overlay(drop_apk_new: false)
        Dir.glob("**/*", File::FNM_DOTMATCH, base: overlay).sort.each do |relative|
          next if relative.end_with?("/.", "/..") || relative == "."

          source = File.join(overlay, relative)
          target = File.join(root, relative)
          if File.symlink?(source)
            FileUtils.rm_f(target)
            File.symlink(File.readlink(source), target)
          elsif File.directory?(source)
            FileUtils.mkdir_p(target)
          else
            FileUtils.mkdir_p(File.dirname(target))
            FileUtils.rm_f(target)
            FileUtils.install(source, target, mode: File.stat(source).mode & 0o7777)
            FileUtils.rm_f("#{target}.apk-new") if drop_apk_new
          end
        end
      end

      def disk_usage(path)
        shell.capture("du", "-sk", path).split.first.to_i * 1024
      rescue CommandFailed
        0
      end
    end
  end
end
