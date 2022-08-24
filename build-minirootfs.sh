#!/bin/sh

# OBS: This script must be called from 'build.sh'

ROOTFSDL="https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/alpine-minirootfs-3.16.2-x86_64.tar.gz"
APKS="alpine-base openrc busybox-initscripts busybox kbd-bkeymaps chrony dhcpcd e2fsprogs haveged network-extras openntpd openssl openssh tzdata wget sigma-rootfs"
INITFS_FEATURES="ata base bootchart cdrom ext4 mmc nvme raid scsi squashfs usb virtio"

cd "$CACHEDIR"

# create base structure
mkdir -p base
mkdir -p content
mkdir -p content/boot/grub
mkdir -p initrd/bin
mkdir -p apkcache

# download/extract minirootfs
wget "$ROOTFSDL" -O base.tar.gz
tar -zxf base.tar.gz -C base/

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

# create squashfs
mksquashfs base content/profile.sfs -comp zstd -Xcompression-level 9

# create initfs
cp "$PROFILEDIR"/initfs ./
mkinitfs -i initfs -F "$INITFS_FEATURES" -o content/boot/initramfs

# create grub entry
cp "$PROFILEDIR"/grub.cfg content/boot/grub/grub.cfg

# build iso
cp /boot/vmlinuz-lts content/boot/vmlinuz

grub-mkrescue \
    -o "$OUTDIR/$PROFILENAME"-linux.iso \
    -sysid LINUX \
    -volid "$PROFILENAME-linux" \
    content

cd "$BASEDIR"

