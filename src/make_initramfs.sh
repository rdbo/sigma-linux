#!/bin/sh

mkdir -p "$INITRD_DIR"
cd "$INITRD_DIR"

# Create init script
cat <<- EOF > init
#!/bin/sh

dmesg -n 1
mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys
setsid cttyhack /bin/sh
EOF
chmod +x init

# Compress files into initramfs
find . | cpio -R root:root -H newc -o | gzip > "$INITRAMFS_PATH"

cd "$ROOT_DIR"
