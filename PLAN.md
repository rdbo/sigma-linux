# Build system rework

Rework of the Sigma Linux build system: Bash → Ruby, monolithic script → staged
pipeline, plus a fix for GRUB losing its theme on kernel updates.

Legend: `[x]` done and verified · `[~]` done, verification pending · `[ ]` to do

---

## 1. Where we start

What the current build does, end to end (`build.sh`, run as root inside Docker):

| Step | Script | Notes |
|---|---|---|
| Stage APKs | `src/setup_apks.sh` | One hand-written block per package; special cases tar `rootfs/` and `sent/` into source tarballs. Skips a package if its staging dir exists, so edits to an APKBUILD are **never** picked up until `cache/` is wiped. |
| Build repo | `src/build_repo.sh` | Skips a package if *any* `.apk` with its name prefix is in the repo, so version bumps are ignored too. `abuild -kK` keeps every build tree: **15 GB** in `cache/apk` today. |
| Rootfs + squashfs | `src/make_squashfs.sh` | Installs the whole profile with `--allow-untrusted --no-cache` (no signature checks on *Alpine's* packages, and re-downloads ~1-2 GB on every build). Skips installing if `/etc/apk` exists, so a rebuilt kernel never lands in the image. Config files written via heredocs. |
| ISO | `src/make_iso.sh` | Writes `grub.cfg` from a heredoc; theme values (gfxmode, wallpaper, VT colours) live only here. |

Problems worth fixing beyond the language:

- **No way to do part of the work.** You can't build one package and stop, rebuild the image without
  rebuilding packages, or re-run just the ISO step, short of commenting code out.
- **Staleness everywhere.** Every "skip if exists" check is a stale-cache trap (see the table).
- **Nothing persists between containers.** abuild downloads (the 150 MB kernel tarball), the apk
  package cache and the abuild signing key all live inside the container and vanish with it.
- **Root-owned files** in `cache/` on the host (hence the `chmod 777`).
- **CI is broken.** The workflow does `uses: ./`, which needs an `action.yml` at the repo root (there is
  none), and Docker actions aren't privileged, so `mount --rbind` / `chroot` couldn't work anyway.
- Junk committed by in-place abuild runs (`src/apk/sigma-vt323/src/*.tar.xz` symlinks to `/app/...`).

### The GRUB bug (root cause found)

Alpine's grub package ships this trigger:

```sh
if grep -q '^disable_trigger=1' /etc/update-grub.conf 2>/dev/null; then exit 0; fi
exec /usr/sbin/update-grub
```

The build writes **`/etc/upgrade-grub.conf`**: wrong file name, so the guard never applied, and every
kernel update ran a stock `grub-mkconfig` over the hand-made config. (This machine also has
`disable_trigger=yes`, which wouldn't match either.)

Just fixing the file name would stop the overwrite, but it would also stop GRUB from ever picking up kernel
changes (for example a second kernel installed next to `linux-sigma`). Running stock
`grub-mkconfig` isn't an option either, because its output can't boot with initrdbo:

- initrdbo **requires** `rootfstype=` on the command line, or it drops to a troubleshooting shell;
- on encrypted installs `root=` must name the **LUKS container** (initrdbo unlocks it itself), while
  `grub-mkconfig` emits the UUID of the filesystem *inside* the container;
- the theme (640x480 gfxterm, wallpaper, `vt.*` colours) isn't in `/etc/default/grub` at all.

**Fix:** make `grub-mkconfig` produce the Sigma config instead of fighting it (Phase 5).

---

## 2. Decisions

### Ruby, stdlib only
No gems. The tool must run on the host (to dispatch into Docker), inside the Alpine container, and in CI,
and Ruby's stdlib already covers it all: `optparse`, `yaml`, `json`, `digest`, `open3`, `erb`, `fileutils`.
Nothing to `bundle install`, nothing to break.

### A purpose-built CLI, not Rake / Make / Thor
I weighed the obvious alternatives:

- **Rake / Make**: give a dependency graph for free, but their freshness model is file mtimes. Our inputs
  are directories, remote repositories and config values, so the stamp logic has to be custom anyway.
  "Run just this stage" fights them (they always walk prerequisites), task arguments read badly
  (`rake 'pkg[linux-sigma]'`), and the output can't be made pleasant.
- **Thor**: a gem dependency in exchange for option parsing we get from `optparse`.

The pipeline itself is small (four stages, linear), so a purpose-built runner is less code than adapting a
general one, and it lets the output be designed rather than inherited.

### Stages, steps and selections
The build is a linear pipeline of **stages**, each made of named **steps**:

```
packages ──▶ rootfs ──▶ squashfs ──▶ iso
```

| Stage | Produces | Steps |
|---|---|---|
| `packages` | signed local repo `cache/repo/` | one per local package (built on demand, in dependency order) |
| `rootfs` | `cache/rootfs/`, `cache/boot/` | `prepare`, `install`, `configure` |
| `squashfs` | `cache/rootfs.squashfs` | `compress` |
| `iso` | `out/sigma-linux.iso` | `stage`, `grub`, `image` |

Selection syntax (one grammar for everything):

```
sigma build                       # whole pipeline, skipping stages that are up to date
sigma build rootfs                # just that stage (named ⇒ always runs)
sigma build rootfs..              # rootfs and everything after it
sigma build ..squashfs            # everything up to squashfs
sigma build packages:linux-sigma  # a subset of a stage: one package…
sigma build rootfs:configure      # …or one step
sigma pkg linux-sigma initrdbo    # shortcut for packages:<names>
```

**Freshness model.** Each stage has a fingerprint (hash of its inputs: source files, relevant config, and
the fingerprint of the stage before it) stored in `cache/state/`. A bare `sigma build` skips a stage whose
fingerprint matches and whose outputs exist. Naming a stage means "do it" and it always runs. Packages
are tracked individually: a package rebuilds when its directory content changes or its `.apk` files are
missing. That fixes the "edited the APKBUILD, nothing happened" trap. Remote Alpine updates are not
fingerprinted; `--force` or naming the stage covers that.

**Local packages are built on demand.** The packages stage builds the local packages the selected profile
needs (plus their local dependencies), not everything under `packages/`. Unused recipes (`sigma-dwl`,
`sigma-st`, `simplex-chat`) stop costing build time but stay buildable by name.

### Configuration: YAML, layered
`config/sigma.yml` (committed defaults) ← `config/local.yml` (git-ignored, replaces
`config.override.sh`) ← `--set key=value` on the command line. `sigma config` prints the merged result.

### Docker by default, native when it makes sense
`./sigma …` on the host builds the image if needed and re-runs itself inside the container with the same
arguments. Inside the container (or with `--native`) it runs directly. `sigma shell` replaces
`docker-env.sh`. Building a single package natively on a Sigma host works too, since abuild doesn't need root.

### Layout

```
sigma                     CLI entry point
lib/sigma/                the build system
config/sigma.yml          build configuration
config/repositories       Alpine repositories for the image (was src/repositories)
packages/<name>/          local APKBUILDs (was src/apk/)
profiles/*.list           package profiles with @include (were src/pkglist.*)
image/overlay/            files copied verbatim onto the rootfs (were heredocs)
image/grub.cfg.erb        live ISO boot menu template
cache/                    intermediate state (safe to delete)
out/                      final artifacts (the ISO)
```

---

## 3. Phases

### Phase 1: Core toolkit ✅
The Ruby foundation everything else stands on: no build logic yet.

- [x] `sigma` entry point and `lib/sigma.rb` loader
- [x] `UI`: palette (Sigma teal, truecolor → 256 → none), `NO_COLOR`, TTY detection, headers,
      step lines with spinner + elapsed time + live last-output-line, failure box with log tail, summary
- [x] `Shell`: run commands with output captured to per-step log files, live or verbose streaming,
      `as_builder` (drop to the abuild user when root), `chroot`, clear errors
- [x] `Config`: YAML defaults + local + `--set` overrides, deep merge, typed accessors, derived paths
- [x] `CLI`: subcommands (`build`, `pkg`, `status`, `clean`, `config`, `shell`, `run`), help text
- [x] **Check:** `sigma --help`, `sigma config`, `sigma config --set squashfs.compression=zstd`, and a UI
      demo exercising success / failure / non-TTY output

### Phase 2: Layout and data ✅
Move sources into their new homes and turn heredocs into data. Content stays identical.

- [x] `src/apk/` → `packages/` (git mv), drop committed abuild junk (`sigma-vt323/src/`)
- [x] Profiles: `minimal` ⊂ `standard` ⊂ `full` rewritten with `@include` and `-pkg` removals
- [x] **Check:** each new profile resolves to *exactly* the same package set as the old list
      (minimal 155, standard 237, full 243 packages: identical)
- [x] Heredoc files → `image/overlay/` (`issue`, `motd`, `fstab`, `network/interfaces`, `doas.conf`,
      `conf.d/zram-init`, `modules`); services, user and skel dirs → `config/sigma.yml`
- [x] **Check:** overlay files byte-identical to what the heredocs produced (shell-rendered and diffed)
- [x] The GRUB wallpaper moved into `sigma-conf` (`/usr/share/sigma/grub/`), ready for Phase 5

### Phase 3: The pipeline ✅
Port the four stages onto the toolkit, with the selection grammar and freshness model.

- [x] `Pipeline`: stage registry, selection parsing (`a`, `a..`, `..b`, `a..b`, `a:x,y`), fingerprints,
      stamps in `cache/state/`, skip-if-fresh, end-of-run summary
- [x] `APKBUILD` reader (sources the file in `sh`, never `eval`s it in Ruby) and local package graph
      (profile → needed packages via names / subpackages / provides, topological order)
- [x] Stage `packages`: generic staging (a `foo.tar.gz` source with a sibling `foo/` dir is tarred
      reproducibly; no per-package code), `abuild checksum`, build, prune superseded `.apk`s, re-index,
      remove build trees on success
- [~] Stage `rootfs`: fresh root each run, signed install (Alpine keys + our key, **no
      `--allow-untrusted`**), persistent apk cache, overlay (before install for triggers, after to win),
      services, user, merge-usr; mounts always torn down, even on failure or Ctrl-C
- [~] Stage `squashfs`, stage `iso` (boot entry per installed kernel, rendered from template)
- [x] `status` and `clean` commands
- [x] **Check:** selection grammar unit-tested; APKBUILD reader and package graph tested against the real
      `packages/`; dry run (`--plan`) prints the right stages / steps for each selection.
      `ruby test/run.rb`: 23 tests, including freshness (inputs / upstream token / partial runs) and the
      ISO menu rendering byte-identical to the old `make_iso.sh` output. Stages marked `[~]` run for real in
      Phase 4 (packages) and Phase 6 (rootfs, squashfs, iso).

### Phase 4: Container and caching ✅
- [x] Dockerfile: one documented package layer, `ccache`, build user with host UID, no keygen baked
      into the image, `SIGMA_CONTAINER=1`, minimal build context
- [x] Persistent caches under `cache/`: abuild sources (`downloads/sources/`), apk packages (`downloads/apk/`), ccache,
      abuild signing keys (`keys/`)
- [x] Docker dispatch from the host (`build` / `shell` / everything), cross-arch binfmt setup kept
- [x] Host-owned outputs (no more root-owned `cache/` / `out/` on the host)
- [~] CI workflow rewritten to run the same `./sigma build` in a privileged container (can't be run from
      here; mirrors the local invocation exactly, plus freeing runner disk space)
- [x] **Check:** image builds; `sigma shell` works; `sigma pkg initrdbo` builds a package end to end
      in the container; a second run is a no-op; editing the APKBUILD triggers a rebuild.
      Also verified: a `pkgrel` bump builds `-r1` and prunes `-r0` from the signed index (and back);
      `sigma-conf` / `sigma-sent` sources packed reproducibly by the generic rule; makedepends served from
      the shared apk cache; outputs, logs, stamps and the (0600) key owned by the host user.

### Phase 5: GRUB that survives kernel updates
- [x] `sigma-conf` ships the theme as data: `/usr/share/sigma/grub/grub.conf` (shell-sourceable
      `GRUB_*` vars: gfxmode, gfxterm, background, font, VT colours, timeout, top-level kernel) and
      `wallpaper.png`; the *same file* drives the ISO menu, so the theme lives in one place
- [x] `sigma-grub-setup` (installed system): writes `/etc/default/grub` that sources the theme and pins
      `root=` / `rootfstype=` for initrdbo (LUKS-aware), installs the wallpaper on `/boot`, removes the
      legacy guard files, runs `update-grub`. Re-runnable, so it also migrates existing installs.
- [x] `setup-sigma` uses it instead of copying and `sed`-patching the ISO's `grub.cfg`; it now
      bind-mounts the live `/dev` into the chroot (grub-mkconfig must resolve `/dev/mapper/…` on LUKS)
      and mounts `/sys`
- [x] Build: trigger correctly disabled *during* the image build only, removed before shipping
- [x] Menu layout matches the old one: the Sigma kernel is the plain "Sigma Linux" entry
      (`GRUB_TOP_LEVEL`), other kernels go under "Advanced options for Sigma Linux"
- [~] **Check:** container + loop-device test, three scenarios (plain, LUKS, migrating an old-style install):
      48/48 checks passed, including apk's real grub trigger regenerating the menu on a kernel install
      with theme, `root=UUID=<partition or LUKS container>`, `rootfstype` and VT colours intact, overrides
      kept across re-runs, and grub's post-upgrade leaving the cmdline alone. After the last tweak (submenu
      layout) the setup checks passed again, but the run was cut off by the crash below, before the
      kernel-update part. **Remaining verification moves into the Phase 6 VM test; no more loop / dm
      devices on the host kernel.**

### Phase 6: Cut-over and end-to-end
- [x] Remove the Bash build (`build.sh`, `docker-env.sh`, `src/*.sh`, `start*.sh`, `sensible_clean.sh`); every
      feature checked off against the Ruby port first (one deliberate difference: empty `/dev`, `/proc`,
      `/boot` mountpoints stay in the image instead of being deleted; initrdbo and `setup-sigma` `mkdir -p`
      them anyway)
- [x] README: build documentation
- [x] `sigma run --disk FILE [--no-iso]` to try the installer in QEMU (replaces `start*.sh`)
- [ ] **Check:** the runbook below, run by hand, one step at a time

#### Runbook

You run these; I don't. Nothing heavy runs in parallel. **Stop at the first step that doesn't look as
described** and send me the error box (plus `cache/logs/latest/<stage>/<step>.log` if it names one).
Steps 1-4 are light; 5 is the long one.

0. **Protect the work.** Commit and push (see the chat), and ideally check the SSD's health:
   `doas smartctl -a /dev/nvme0` (look at *Media and Data Integrity Errors*, *Percentage Used*, *Available Spare*).

1. **No Docker yet.** `ruby test/run.rb` → `23 runs, … 0 failures`. Then `./sigma build --plan` → four
   stages; `packages` says 11 packages, 8 to build (initrdbo, biblegen and sigma-sent were built before the
   crash). `./sigma status` → a table, nothing broken.

2. **Container, and leftovers from the crash.** `doas rc-service docker start`, then
   `docker run --rm -v "$PWD/cache:/c" alpine:edge rm -rf /c/grubtest /c/build/sigma/linux-sigma`
   (~7 GB of root-owned files). `./sigma shell` should drop you into `/app` as root; `exit`.

3. **Small packages.** `./sigma pkg initrdbo sigma-conf biblegen` → `sigma-conf` builds (✓, seconds; it
   has the new GRUB files); `initrdbo` and `biblegen` show ○ up to date. That proves the per-package
   freshness survived the crash.

4. **The rest except the kernel.** `./sigma pkg rdbo-archives sigma-firacode-nerd sigma-flat-remix-gtk
   sigma-material-symbols sigma-sent sigma-vt323 sigma-wvkbd` → seven ✓.

5. **The kernel, alone.** Nothing else running on the machine. For the first time, go easier than the
   default: `./sigma pkg linux-sigma --set jobs=6`. Expect 30-90 minutes; it peaks around 15-20 GB of disk
   (`df -h /` now and then is wise) and cleans its build tree up when it succeeds. If the desktop gets
   sluggish, Ctrl-C is safe: nothing is mounted during package builds, and the next run starts the package over.

6. **Root filesystem.** `./sigma build rootfs` → `prepare`, `install 237 packages` (downloads ~1-2 GB the
   first time; cached after), `configure`. Then: `./sigma status` → packages and rootfs up to date.

7. **Image.** `./sigma build squashfs..` → squashfs (several minutes with xz) and the ISO in `out/`.

8. **Boot it** (needs QEMU on the host: `doas apk add qemu-system-x86_64 qemu-img qemu-ui-gtk ovmf`).
   `./sigma run` (BIOS) and `./sigma run --uefi`: the Sigma menu (wallpaper, 640x480), boots to the live
   desktop. Log in as `user` / `pass`.

9. **Install test, in the VM only.** `./sigma run --uefi --disk cache/vm.qcow2` → in the live system:
   `doas setup-sigma`, disk `/dev/nvme0n1` (the VM disk is NVMe, like your machine), full-disk encryption
   **y**, random fill **n**, `YES`. Power off, then
   `./sigma run --uefi --disk cache/vm.qcow2 --no-iso`:
   - the menu shows the wallpaper and a plain **Sigma Linux** entry; the LUKS passphrase prompt appears;
     the desktop comes up;
   - `cat /proc/cmdline` has `root=UUID=…`, `rootfstype=ext4` and the `vt.default_*` colours;
   - **the kernel-update test:** `doas apk add linux-lts`; the output shows the grub trigger running.
     `doas reboot`: same themed menu, *Advanced options for Sigma Linux* now lists the lts kernel, and
     the default entry still boots.
   - Optional: repeat with encryption **n** on a fresh disk (`rm cache/vm.qcow2`).

10. **Incremental behaviour.** `./sigma build` → "Everything is up to date". `./sigma build iso` → only the
    iso stage runs.

11. **Optional, last: migrate your own machine's GRUB.** This touches your real bootloader, so dry-run first:
    1. `./sigma pkg sigma-conf`, then trust the key once: `doas cp cache/keys/*.pub /etc/apk/keys/`.
    2. `doas apk add --repository "$PWD/cache/repo/sigma" sigma-conf`
    3. `doas sigma-grub-setup --no-update`, then read `/etc/default/grub`: `GRUB_DEVICE_UUID` must equal the
       `root=UUID=` in your `/proc/cmdline`.
    4. `doas grub-mkconfig -o /tmp/grub.cfg.new` and compare with `/boot/grub/grub.cfg`: same root UUID,
       `rootfstype=ext4`, the colours, the wallpaper.
    5. Only then `doas update-grub` (it keeps the old file as `grub.cfg.backup`).

---

## 4. Risks and notes

- **Incident during development: the build host became unresponsive** (I/O errors; a reboot recovered it
  cleanly) while a kernel build using every core ran *alongside* a loop-device test. The cause couldn't be
  proven; most likely the storage stack stalled under the combined load. Safeguards since:
  - `jobs: auto` = CPUs − 1, capped at one job per 1.5 GiB of RAM;
  - compiles and compression run under `nice`;
  - anything that partitions, formats or opens LUKS runs inside a QEMU VM, never against the host kernel;
  - one heavy job at a time.

- **Disk space.** A kernel build peaks around 15-20 GB; the rootfs, squashfs and ISO add ~10 GB. `cache/grubtest/` and the interrupted
  `cache/build/sigma/linux-sigma/` (~7 GB, root-owned) still need removing through a container.
- **CI can't be exercised locally**; the workflow is written to mirror the local container invocation.
- Kernel updates on an installed system: the initramfs name is per-flavor (`initramfs-sigma`), so the order
  in which the initrdbo and grub triggers run doesn't matter for an existing kernel.
