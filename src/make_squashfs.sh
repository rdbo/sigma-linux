#!/bin/sh

set -e

mkdir -p "$SQUASHFS_DIR"

# Install kernel modules
if [ ! -d "$SQUASHFS_DIR/lib/modules" ]; then
	cd "$KERNEL_DIR"
	make INSTALL_MOD_PATH="$SQUASHFS_DIR" modules_install
	cd "$ROOT_DIR"
fi

pkgs="$(cat "$SRC_DIR/pkglist" | sed 's/#.*//g' | tr '\n' ' ')"
echo "Packages: $pkgs"

# Initialize APK database
if [ ! -d "$SQUASHFS_DIR/etc/apk" ]; then
	apk add --initdb -p "$SQUASHFS_DIR"
fi

# Install packages
apk add \
	-p "$SQUASHFS_DIR" \
	--allow-untrusted \
	--no-cache \
	--repositories-file="$REPOS_FILE" \
	-X "$REPO_DIR/apk" \
	$pkgs

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

mkdir -p "$SQUASHFS_DIR/etc"
echo "$PROFILENAME" > "$SQUASHFS_DIR/etc/hostname"

> "$SQUASHFS_DIR/etc/fstab"

# Add default network interfaces configuration
mkdir -p "$SQUASHFS_DIR/etc/network"
cat <<- EOF > "$SQUASHFS_DIR/etc/network/interfaces"
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
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
size0=`LC_ALL=C free -m | awk '/^Mem:/{print int($2/2)}'` # 50% of memory reserved for zram
maxs0=1
algo0=zstd
labl0=zram_swap
EOF

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
# rc_add modloop sysinit # NOTE: Not working, but there doesn't seem to be harm done without it

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
rc_add networking default
rc_add earlyoom default
rc_add iwd default
rc_add dbus default
rc_add seatd default
# rc_add bluetooth default # TODO: Add bluetooth

# Create squashfs
rm -f "$SQUASHFS_PATH" # Avoid appending to existing squashfs file
mksquashfs "$SQUASHFS_DIR" "$SQUASHFS_PATH" -comp xz
