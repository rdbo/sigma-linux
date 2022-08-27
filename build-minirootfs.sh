#!/bin/sh

# OBS: This script must be called from 'build.sh'

ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/alpine-minirootfs-3.16.2-x86_64.tar.gz"
APKS="alpine-base openrc busybox-initscripts busybox kbd-bkeymaps chrony dhcpcd e2fsprogs haveged network-extras openntpd openssl openssh tzdata wget"
INITFS_FEATURES="ata base bootchart cdrom ext4 mmc nvme raid scsi squashfs usb virtio"

cd "$CACHEDIR"

# create base structure
mkdir -p kernel
mkdir -p base
mkdir -p final
mkdir -p final/boot/grub
mkdir -p apkcache

# download/extract minirootfs
if [ ! -f "base.tar.gz" ]; then
    wget "$ROOTFS_URL" -O base.tar.gz
fi
tar -zxf base.tar.gz -C kernel/
tar -zxf base.tar.gz -C base/

# install kernel
if [ ! -f kernel/boot/vmlinuz-edge ]; then
    apk add \
        --root kernel/ \
        --cache-dir apkcache/ \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
        linux-edge
fi

cp kernel/boot/vmlinuz-edge final/boot/vmlinuz

# install apks on minirootfs
apk add \
    --root base/ \
    --cache-dir apkcache/ \
    --allow-untrusted \
    --force-overwrite \
    --repository "$REPODIR/apk/" \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    $APKS

# filesystem changes
echo "$PROFILENAME" > base/etc/hostname

mkdir -p base/etc/local.d
cp "$PROFILEDIR"/setup.start base/etc/local.d/

# create squashfs
mksquashfs base final/profile.sfs

# create initfs
KERNEL_VERSION="$(ls kernel/lib/modules | head -1)"
cp "$PROFILEDIR"/initfs ./
mkinitfs -b kernel/ -i initfs -F "$INITFS_FEATURES" -o kernel/boot/initramfs "$KERNEL_VERSION"
cp kernel/boot/initramfs final/boot/

# create grub config
cp "$PROFILEDIR"/wallpaper-grub.png final/boot/wallpaper.png
cp "$PROFILEDIR"/grub.cfg final/boot/grub/grub.cfg

# build iso
grub-mkrescue \
    -o "$OUTDIR/$PROFILENAME"-linux.iso \
    -sysid LINUX \
    -volid "$PROFILENAME-linux" \
    final

# cleanup
rm -rf base/ final/

cd "$BASEDIR"

