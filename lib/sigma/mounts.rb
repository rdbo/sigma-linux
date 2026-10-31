# frozen_string_literal: true

require "fileutils"

module Sigma
  # Bind mounts for chroot-style work, and the safety net around them.
  #
  # The image root gets the host's /dev and /proc bind-mounted into it while
  # packages install. Deleting that root while anything is still mounted would
  # recurse into the real /dev, so every removal goes through #remove_tree,
  # which refuses to touch a path with live mounts underneath.
  module Mounts
    module_function

    # Mount points at or below +path+, deepest first.
    def under(path)
      path = File.expand_path(path)
      File.readlines("/proc/self/mountinfo").filter_map do |line|
        point = line.split(" ")[4].gsub(/\\([0-7]{3})/) { Regexp.last_match(1).to_i(8).chr }
        point if point == path || point.start_with?("#{path}/")
      end.uniq.sort_by { |p| -p.length }
    rescue Errno::ENOENT
      []
    end

    def mounted?(path) = under(path).include?(File.expand_path(path))

    # Recursive bind mount, made a slave so unmounting it later can never
    # propagate back to the source (the same thing arch-chroot does).
    def bind(shell, task, source, target)
      FileUtils.mkdir_p(target)
      shell.run(task, "mount", "--rbind", source, target)
      shell.run(task, "mount", "--make-rslave", target)
    end

    # Unmounts everything below +path+, falling back to a lazy unmount for
    # anything still busy.
    def release(shell, task, path)
      under(path).each do |point|
        next unless mounted?(point) # a recursive unmount may already have taken it

        begin
          shell.run(task, "umount", "-R", point)
        rescue CommandFailed
          shell.run(task, "umount", "-R", "-l", point)
        end
      end
      return if under(path).empty?

      raise Error.new("could not unmount #{under(path).join(", ")}",
                      hint: "Unmount them by hand (umount -R -l <path>) before trying again.")
    end

    def remove_tree(path)
      live = under(path)
      unless live.empty?
        raise Error.new("refusing to delete #{path}: still mounted at #{live.join(", ")}",
                        hint: "Run `sigma clean rootfs`, which unmounts first, or unmount by hand.")
      end

      FileUtils.rm_rf(path)
    end
  end
end
