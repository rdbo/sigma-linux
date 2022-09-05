#!/bin/sh

# OBS: This script must be called from 'build.sh'

cd "$CACHEDIR"

# create base structure
mkdir -p kernel
mkdir -p base
mkdir -p base/lib/modules
mkdir -p final
mkdir -p final/boot/grub
mkdir -p apkcache

# download/extract minirootfs
if [ ! -f "base.tar.gz" ]; then
    wget "$ROOTFS_URL" -O base.tar.gz
fi
tar -zxf base.tar.gz -C kernel/
tar -zxf base.tar.gz -C base/

# cache all required apks
if [ ! -d apkcache/$PROFILEARCH ]; then
    mkdir -p apkcache/$PROFILEARCH
    cd apkcache/$PROFILEARCH

    apk fetch \
        --recursive \
        --no-cache \
        --allow-untrusted \
        --arch "$PROFILEARCH" \
        --repository "$REPODIR/apk/" \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        $ROOTFS_APKS linux-$KERNEL_FLAVOR

    cd "$CACHEDIR"
fi

# install kernel
if [ ! -f kernel/boot/vmlinuz-$KERNEL_FLAVOR ]; then
    apk add \
        --root kernel/ \
        --no-cache \
        --arch "$PROFILEARCH" \
        --repository "$CACHEDIR"/apkcache/ \
        linux-$KERNEL_FLAVOR alpine-conf mdev-conf
fi

cp kernel/boot/System.map-$KERNEL_FLAVOR final/boot/
cp kernel/boot/System.map-$KERNEL_FLAVOR final/boot/System.map
cp kernel/boot/vmlinuz-$KERNEL_FLAVOR final/boot/vmlinuz
cp -r kernel/lib/modules/. base/lib/modules/

# install apks on minirootfs
apk add \
    --root base/ \
    --no-cache \
    --allow-untrusted \
    --force-overwrite \
    --arch "$PROFILEARCH" \
    --repository "$CACHEDIR"/apkcache/ \
    $ROOTFS_APKS

# filesystem changes
echo "$PROFILENAME" > base/etc/hostname

mkdir -p base/etc/local.d
cp "$PROFILEDIR"/setup.start base/etc/local.d/

# add services
rc_add() {
    mkdir -p base/etc/runlevels/$2
    ln -sf /etc/init.d/$1 base/etc/runlevels/$2/$1
}

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
# rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

rc_add dbus default
rc_add udev sysinit
rc_add udev-trigger sysinit
rc_add udev-settle sysinit
rc_add udev-postmount default
rc_add local default
rc_add lightdm default
rc_add iwd default

# create squashfs
mksquashfs base final/profile.sfs -comp zstd -Xcompression-level $ZSTD_LEVEL

# create initfs
KERNEL_VERSION="$(ls kernel/lib/modules | head -1)"
mkinitfs -b kernel/ -i "$PROFILEDIR"/initfs -F "$INITFS_FEATURES" -o final/boot/initramfs "$KERNEL_VERSION"

# create grub config
cp "$PROFILEDIR"/wallpaper-grub.png final/boot/wallpaper.png
cp "$PROFILEDIR"/grub.cfg final/boot/grub/grub.cfg

# build iso
grub-mkrescue \
    -o "$OUTDIR"/$PROFILENAME-linux-$PROFILEARCH.iso \
    -sysid LINUX \
    -volid "$PROFILENAME-linux" \
    final

# cleanup
rm -rf base/ final/

cd "$BASEDIR"

