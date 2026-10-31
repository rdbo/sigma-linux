# frozen_string_literal: true

require "fileutils"

module Sigma
  module Stages
    # Compresses the root filesystem into cache/rootfs.squashfs, which the
    # live ISO boots from.
    class Squashfs < Stage
      stage "squashfs", "compressed root image", steps: %i[compress]

      def inputs = Fingerprint.of(config.dig("squashfs"))
      def outputs = [paths.squashfs]

      def check_prerequisites
        require_output(File.join(paths.rootfs, "etc", "apk", "world"), "rootfs")
        return if Mounts.under(paths.rootfs).empty?

        raise Error.new("#{relative(paths.rootfs)} still has things mounted in it",
                        hint: "An earlier run was interrupted; `sigma build rootfs` cleans it up.")
      end

      protected

      def step_label(_step) = "compress (#{config.fetch("squashfs.compression")})"
      def summary = ui.bytes(File.size(paths.squashfs))

      def step_compress(task)
        FileUtils.mkdir_p(File.dirname(paths.squashfs))
        shell.run(task, "mksquashfs", paths.rootfs, paths.squashfs, "-noappend",
                  "-comp", config.fetch("squashfs.compression"), "-processors", config.jobs,
                  *Array(config.dig("squashfs.args")), heavy: true)
        task.detail = ui.bytes(File.size(paths.squashfs))
      end
    end
  end
end
