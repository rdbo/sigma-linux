# frozen_string_literal: true

require "fileutils"

module Sigma
  module Stages
    # Builds the local packages into a signed repository at cache/repo/.
    #
    # Each package is tracked on its own: it rebuilds when anything in its
    # packages/<name>/ directory changes, or when its .apk files are missing.
    # Packages build in a disposable copy (cache/build/), so abuild never
    # writes into the source tree.
    class Packages < Stage
      stage "packages", "local APK repository"

      TARBALL = /\.(tar\.(gz|xz|zst|bz2)|tgz)\z/

      def local
        @local ||= LocalPackages.new(File.join(paths.root, "packages"), shell: shell, carch: config.arch)
      end

      # The packages a run covers: the named ones, or what the profile needs.
      def selected(items = nil)
        items ? local.for_names(items) : local.for_profile(@pipeline.profile.packages)
      end

      def validate(items) = local.for_names(items)

      def plan(items)
        list = selected(items)
        pending = list.reject { |pkg| package_status(pkg).first == :fresh }
        "#{ui.plural(list.size, "package")} (#{pending.empty? ? "all up to date" : "to build: #{pending.map(&:name).join(", ")}"})"
      end

      def inputs = Fingerprint.of(selected.map { |pkg| [pkg.name, fingerprint(pkg)] })

      # Changes whenever a package the profile uses is rebuilt.
      def token = Fingerprint.of(selected.map { |pkg| state.read(package_key(pkg))&.fetch("token", nil) })

      def status
        pending = selected.map { |pkg| [pkg, package_status(pkg)] }.reject { |_, (s, _)| s == :fresh }
        return [:fresh, nil] if pending.empty?
        return [:missing, "never built"] if pending.all? { |_, (s, _)| s == :missing } && pending.size == selected.size

        [:stale, "#{ui.plural(pending.size, "package")} to build"]
      end

      def package_status(pkg)
        stamp = state.read(package_key(pkg))
        return [:missing, "never built"] unless stamp
        return [:stale, "#{stamp["version"]} → #{pkg.version}"] if stamp["version"] != pkg.version
        return [:stale, "recipe changed"] if stamp["fingerprint"] != fingerprint(pkg)
        return [:stale, "APKs missing"] unless stamp["apks"].all? { |apk| File.exist?(File.join(arch_dir, apk)) }

        [:fresh, nil]
      end

      def run(items, force: false)
        list = selected(items)
        signing = Signing.new(context)
        prepare_directories
        context.task(name, "signing-key", label: "signing key") do |t|
          had_key = signing.private_key
          signing.ensure(t)
          signing.trust_here
          t.detail = had_key ? File.basename(signing.private_key) : "generated #{File.basename(signing.private_key)}"
        end

        built = list.count do |pkg|
          state_now, reason = package_status(pkg)
          if state_now == :fresh && !force
            ui.line(:skip, label(pkg), "up to date")
            next false
          end

          build(pkg, signing.private_key, reason: force && state_now == :fresh ? "forced" : reason)
          true
        end

        @summary = [built.positive? ? "#{built} built" : nil, "#{list.size - built} up to date"].compact.join(" · ")
        @summary = ui.plural(list.size, "package") if built == list.size
        install_hint(list) if items
        @summary
      end

      def clean(items = nil)
        if items
          validate(items)
          items.map { |item| local[item] }.uniq.each do |pkg|
            (state.read(package_key(pkg))&.fetch("apks", []) || []).each { |apk| FileUtils.rm_f(File.join(arch_dir, apk)) }
            state.delete(package_key(pkg))
          end
        else
          [paths.repo, File.dirname(paths.staging)].each { |dir| FileUtils.rm_rf(dir) }
          state.keys("package").each { |key| state.delete(key) }
          state.delete(key)
        end
      end

      protected

      def summary = @summary

      private

      def label(pkg) = "#{pkg.name} #{pkg.version}"
      def package_key(pkg) = "package/#{pkg.name}"
      def arch_dir = File.join(config.repo_dir, config.arch)

      def fingerprint(pkg) = Fingerprint.of(Fingerprint.tree(pkg.dir), config.arch)

      def build(pkg, key, reason:)
        context.task(name, pkg.name, label: label(pkg)) do |task|
          started = ui.clock
          task.detail = reason
          dir = stage_copy(pkg, task)
          task.detail = "checksum"
          abuild(task, dir, key, "checksum")
          task.detail = reason
          abuild(task, dir, key, "-r", "-f", *(config.dig("packages.keep_build_trees") ? ["-K"] : []))
          apks = prune(pkg, task, dir, key)
          state.write(package_key(pkg), "version" => pkg.version, "fingerprint" => fingerprint(pkg),
                                        "apks" => apks, "duration" => ui.clock - started)
          task.detail = "built #{ui.bytes(apks.sum { |apk| File.size(File.join(arch_dir, apk)) })}"
        end
      end

      # A fresh working copy in cache/build/sigma/<name>. A source named
      # foo.tar.gz with a sibling foo/ directory is packed here, reproducibly,
      # which is how sigma-conf ships rootfs/ without per-package code.
      def stage_copy(pkg, task)
        dest = File.join(paths.staging, pkg.name)
        FileUtils.rm_rf(dest)
        FileUtils.copy_entry(pkg.dir, dest, true)
        pkg.local_sources.each do |source|
          next if File.exist?(File.join(dest, source)) || !source.match?(TARBALL)

          stem = source.sub(TARBALL, "")
          next unless File.directory?(File.join(dest, stem))

          compress = source.end_with?("gz") ? ["-I", "gzip -n"] : ["-a"]
          shell.run(task, "tar", "--sort=name", "--mtime=@0", "--owner=0", "--group=0", "--numeric-owner",
                    *compress, "-cf", source, stem, chdir: dest)
        end
        context.give_to_builder(dest, recursive: true)
        dest
      end

      def abuild(task, dir, key, *args)
        shell.run(task, "abuild", "-P", paths.repo, *args, chdir: dir, as: :builder, env: abuild_env(key), heavy: true)
      end

      def abuild_env(key)
        jobs = config.jobs
        env = {
          "SRCDEST" => paths.sources,
          "REPODEST" => paths.repo,
          "PACKAGER" => "#{config.name} builder",
          "PACKAGER_PRIVKEY" => key,
          "JOBS" => jobs,
          "MAKEFLAGS" => "-j#{jobs}"
        }
        env.merge!("USE_CCACHE" => "1", "CCACHE_DIR" => paths.ccache) if config.dig("packages.ccache")
        env
      end

      # Keeps only this version's .apk files for the package's outputs and
      # returns them; re-indexes when older versions were removed.
      def prune(pkg, task, dir, key)
        files = Dir.children(arch_dir).select { |f| f.end_with?(".apk") }
        mine = files.select { |f| pkg.outputs.any? { |o| f.match?(/\A#{Regexp.escape(o)}-\d[^-]*-r\d+\.apk\z/) } }
        current = mine.select { |f| pkg.outputs.any? { |o| f == "#{o}-#{pkg.version}.apk" } }
        stale = mine - current
        raise Error, "abuild finished but produced no APKs for #{pkg.name}" if current.empty?
        return current if stale.empty?

        stale.each { |f| FileUtils.rm_f(File.join(arch_dir, f)) }
        abuild(task, dir, key, "index")
        current
      end

      def prepare_directories
        [paths.staging, paths.repo, paths.sources, paths.ccache].each do |dir|
          FileUtils.mkdir_p(dir)
          context.give_to_builder(dir)
        end
        context.give_to_builder(File.dirname(paths.staging))
        context.give_to_builder(File.dirname(paths.sources))
        share_apk_cache
      end

      # In the container, point apk's cache at cache/downloads/apk: the
      # makedepends `abuild -r` installs for each build then come from disk.
      def share_apk_cache
        return unless Docker.inside? && shell.root?

        FileUtils.mkdir_p(paths.apk_cache)
        return if File.symlink?("/etc/apk/cache") && File.readlink("/etc/apk/cache") == paths.apk_cache

        FileUtils.rm_rf("/etc/apk/cache")
        File.symlink(paths.apk_cache, "/etc/apk/cache")
      end

      # After `sigma pkg`, say where the result is and how to use it here.
      # The hint runs on the host, from the checkout: "$PWD" is expanded there
      # (inside the container the checkout is /app). -u upgrades a package
      # that is already installed instead of leaving the old version.
      def install_hint(list)
        names = list.map(&:name).join(" ")
        repo = "\"$PWD/#{relative(config.repo_dir)}\""
        ui.note "repository  #{relative(config.repo_dir)}/#{config.arch}/"
        ui.note "install here, from the checkout: doas apk add -u --repository #{repo} #{names}"
        ui.note "(trust the key once first: doas cp #{relative(paths.keys)}/*.rsa.pub /etc/apk/keys/)"
      end
    end
  end
end
