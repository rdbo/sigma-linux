#!/bin/sh

set -e

mkdir -p "$INITRD_DIR"
cd "$INITRD_DIR"

# Create init script
cat <<- EOF > init
#!/bin/sh

dmesg -n 1
mkdir -p /dev /proc /sys
mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys
setsid cttyhack /bin/sh
EOF
chmod +x init

# Install busybox
mkdir -p bin usr/bin sbin usr/sbin
cp "$BUSYBOX_DIR/busybox" "$INITRD_DIR/bin/busybox"
chroot . /bin/busybox --install

# Compress files into initramfs
find . | cpio -R root:root -H newc -o | gzip > "$INITRAMFS_PATH"

cd "$ROOT_DIR"
