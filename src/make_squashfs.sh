#!/bin/sh

set -e

mkdir -p "$SQUASHFS_DIR"

# Mount filesystems because some packages write to them
# (e.g /dev/null)
umount -R "$SQUASHFS_DIR/dev" > /dev/null 2>&1 || true
rm -rf "$SQUASHFS_DIR/dev" > /dev/null 2>&1 || true
mkdir -p "$SQUASHFS_DIR/dev"
mount --rbind /dev "$SQUASHFS_DIR/dev"

umount -R "$SQUASHFS_DIR/proc" > /dev/null 2>&1 || true
rm -rf "$SQUASHFS_DIR/proc" > /dev/null 2>&1 || true
mkdir -p "$SQUASHFS_DIR/proc"
mount --rbind /proc "$SQUASHFS_DIR/proc"

# Mount temporary boot dir, which will be populated by the
# kernel and initramfs packages
umount -R "$SQUASHFS_DIR/boot" > /dev/null 2>&1 || true
rm -rf "$SQUASHFS_DIR/boot" > /dev/null 2>&1 || true
mkdir -p "$BOOT_DIR" "$SQUASHFS_DIR/boot"
mount --rbind "$BOOT_DIR" "$SQUASHFS_DIR/boot"

# Disable GRUB triggers since they
# interfere with our GRUB config
mkdir -p "$SQUASHFS_DIR/etc"
echo 'disable_trigger=1' > "$SQUASHFS_DIR/etc/upgrade-grub.conf"

pkgs="$(cat "$SRC_DIR/pkglist.$PKG_PROFILE" | sed 's/#.*//g' | tr '\n' ' ')"
echo "Packages: $pkgs"


# Skip installing APKs if APK database is already set up
if [ ! -d "$SQUASHFS_DIR/etc/apk" ]; then
	# Initialize APK database
	apk add --arch "$DISTRO_TARGET_ARCH" --initdb -p "$SQUASHFS_DIR"

	# Install packages
	apk add \
		-p "$SQUASHFS_DIR" \
		--arch "$DISTRO_TARGET_ARCH" \
		--allow-untrusted \
		--no-cache \
		--repositories-file="$REPOS_FILE" \
		-X "$REPO_DIR/apk" \
		$pkgs
else
	echo "[*] Skipped installing APKs in SquashFS, '/etc/apk' exists"
fi

# Add repositories file to squashfs
mkdir -p "$SQUASHFS_DIR/etc/apk"
cp "$REPOS_FILE" "$SQUASHFS_DIR/etc/apk/repositories"

# Overwrite package owned files
cat <<- EOF > "$SQUASHFS_DIR/etc/issue"
Welcome to Sigma Linux (made by rdbo)
Kernel \r on an \m (\l)
EOF

cat <<- EOF > "$SQUASHFS_DIR/etc/motd"
Welcome to Sigma Linux!

To install the system, run the following command: setup-sigma

For more information about the distribution, see:
 - https://github.com/rdbo/sigma-linux
 - https://wiki.alpinelinux.org

EOF

echo "$PROFILENAME" > "$SQUASHFS_DIR/etc/hostname"

> "$SQUASHFS_DIR/etc/fstab"

# Add default network interfaces configuration
mkdir -p "$SQUASHFS_DIR/etc/network"
cat <<- EOF > "$SQUASHFS_DIR/etc/network/interfaces"
auto lo
iface lo inet loopback
EOF

# Create default doas config
cat <<- EOF > "$SQUASHFS_DIR/etc/doas.conf"
permit persist :wheel
permit nopass root
EOF

# Modify zram-init config
cat <<- EOF > "$SQUASHFS_DIR/etc/conf.d/zram-init"
load_on_start="yes"
unload_on_stop="yes"
num_devices="1"

type0="swap"
flag0=
size0=\`LC_ALL=C free -m | awk '/^Mem:/{print int(\$2/2)}'\` # 50% of memory reserved for zram
maxs0=1
algo0=zstd
labl0=zram_swap
EOF

# Create common user directories in /etc/skel
dirs="Downloads Documents Pictures Videos Music"
for dir in $dirs; do
	mkdir -p "$SQUASHFS_DIR/etc/skel/$dir"
done

# Copy /etc/skel to /root (allows for logging in to the desktop environment as root on live boot)
cp -r "$SQUASHFS_DIR/etc/skel/." "$SQUASHFS_DIR/root/."

# Enable OpenRC services
rc_add() {
	# $1: service name
	# $2: run level
	chroot "$SQUASHFS_DIR" rc-update add "$1" "$2"
}

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
# rc_add modloop sysinit # NOTE: Not necessary on Sigma Linux

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add bootmisc boot
rc_add syslog boot

# NOTE: The 'udev' services are used for setting up /dev and doing things
#       such as changing the ownership of certain devices (e.g /dev/dri/cardN).
#       That behavior allows us to access devices (such as the GPU and the input
#       devices) without root access.
rc_add udev sysinit
rc_add udev-trigger sysinit
rc_add udev-settle sysinit
rc_add udev-postmount default
rc_add hostname boot
rc_add zram-init boot
rc_add networking default # Sets up interfaces based on /etc/network/interfaces
rc_add earlyoom default
rc_add iwd default
rc_add dbus default
rc_add seatd default
rc_add bluetooth default

rc_add local default # used for start scripts

# Setup regular user
useradd -R "$SQUASHFS_DIR" -s /bin/bash -m -G wheel,audio,input,video,seat user
# passwd -R "$SQUASHFS_DIR" -d user
chroot "$SQUASHFS_DIR" sh -c 'printf "user:pass" | chpasswd'

# Merge user patches (https://alpinelinux.org/posts/2025-10-01-usr-merge.html)
chroot "$SQUASHFS_DIR" merge-usr

# Unmount filesystems
umount -R "$SQUASHFS_DIR/proc"
rm -rf "$SQUASHFS_DIR/proc"

umount -R "$SQUASHFS_DIR/dev"
rm -rf "$SQUASHFS_DIR/dev"

umount -R "$SQUASHFS_DIR/boot"
rm -rf "$SQUASHFS_DIR/boot"

# Cleanup firmware files that are not used by any module
# (they can be reinstalled through the `linux-firmware` pkg)
if [ -e "$FIRMWARE_DIR" ]; then
	echo "[*] Skipped firmware cleanup, '$FIRMWARE_DIR' exists"
else
	echo "[*] Cleaning up unused firmware for squashfs..."
	mv "$SQUASHFS_DIR/lib/firmware" "$FIRMWARE_DIR"
	mkdir -p "$SQUASHFS_DIR/lib/firmware"
	# TODO: Make sure that `modinfo` cannot fail. It mail fail due to
	#       the host kernel not being the same as the installer kernel
	find "$SQUASHFS_DIR"/lib/modules -type f -name "*.ko*" | xargs modinfo -F firmware | sort -u | while read fw; do
		for fname in "$fw" "$fw.zst" "$fw.xz"; do
			if [ -e "${FIRMWARE_DIR}/$fname" ]; then
				install -pD "${FIRMWARE_DIR}/$fname" "$SQUASHFS_DIR/lib/firmware/$fname"
				break
			fi
		done
	done
fi

# Create squashfs
rm -f "$SQUASHFS_PATH" # Avoid appending to existing squashfs file
mksquashfs "$SQUASHFS_DIR" "$SQUASHFS_PATH" -comp "$SQUASHFS_COMP" $SQUASHFS_EXTRA_ARGS
