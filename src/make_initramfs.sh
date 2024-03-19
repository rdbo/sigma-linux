#!/bin/sh

set -e

mkdir -p "$INITRD_DIR"
cd "$INITRD_DIR"

# Create init script
# TODO: Look for better way of finding CDROM device
cat <<- EOF > init
#!/bin/sh

dmesg -n 1

echo "Mounting pseudo filesystems..."
mkdir -p /dev /proc /sys
mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys

echo "Populating /dev..."
mdev -s

echo "Mounting cdrom at /cdrom..."

for i in \$(seq 1 5); do
	cdromdev="\$(findfs "LABEL=$ISO_VOLID" | head -n 1)"
	if [ -z "\$cdromdev" ] || [ ! -b "\$cdromdev" ]; then
		echo "Failed to find CDROM device, trying again..."
		sleep 1
	else
		break
	fi
done

if [ -z "\$cdromdev" ] || [ ! -b "\$cdromdev" ]; then
	echo "Failed to find CDROM device, spawning troubleshoot shell..."
	exec /bin/sh
fi

mkdir -p /cdrom
mount "\$cdromdev" /cdrom

echo "Mounting squashfs at /live..."
mkdir -p /live
mount /cdrom/rootfs.squashfs /live

echo "Mounting overlayfs at /new_root..."
mkdir -p /upper /work /new_root
mount -t overlay overlay -o lowerdir=/live,upperdir=/upper,workdir=/work /new_root

echo "Mounting pseudo filesystems for new root.."
mkdir -p /new_root/dev /new_root/proc /new_root/sys
mount -t devtmpfs none /new_root/dev
mount -t proc none /new_root/proc
mount -t sysfs none /new_root/sys

echo "Spawning shell (exit to continue init)..."
/bin/sh

exec switch_root /new_root /sbin/init
EOF
chmod +x init

# Install busybox
mkdir -p bin usr/bin sbin usr/sbin
cp "$BUSYBOX_DIR/busybox" "$INITRD_DIR/bin/busybox"
chroot . /bin/busybox --install

# Compress files into initramfs
find . | cpio -R root:root -H newc -o | gzip > "$INITRAMFS_PATH"

cd "$ROOT_DIR"
