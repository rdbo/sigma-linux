#!/bin/sh

export PROFILENAME="sigma"
export PROFILEVER="3.0"
export PROFILEURL="https://github.com/rdbo/sigma-linux"
export PROFILEARCH="x86_64"
export BASEDIR="$(pwd)"
export CACHEDIR="$BASEDIR/cache"
export PROFILEDIR="$BASEDIR/profile"
export APKDIR="$PROFILEDIR/apk"
export OUTDIR="$BASEDIR/out"
export UNIONFS_SIZE="2G"
export APKLIST="$(sh $PROFILEDIR/apklist.sh)"
export REPODIR="$PROFILEDIR/repo"
export BUILD_CMD="sudo -E sh build-minirootfs.sh"
export ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/$PROFILEARCH/alpine-minirootfs-3.16.2-$PROFILEARCH.tar.gz"
export ROOTFS_APKS="alpine-base openrc busybox-initscripts busybox kbd-bkeymaps chrony dhcpcd e2fsprogs haveged network-extras openntpd openssl openssh tzdata wget sigma-rootfs"
export INITFS_FEATURES="ata base bootchart cdrom ext4 mmc nvme raid scsi squashfs usb virtio"
export KERNEL_FLAVOR="lts"
export ZSTD_LEVEL="22"

# parse args
getval() {
    echo $1 | cut -d '=' -f 2
}

for arg in $@; do
    case $arg in
        # quick build
        "-q") export ZSTD_LEVEL="9";;

        # custom arch
        "-a="*) export PROFILEARCH=$(getval $arg);;

        # custom kernel flavor
        "-k="*) export KERNEL_FLAVOR="$(getval $arg)";;

        # legacy build
        "-l") export BUILD_CMD="sh build-mkimg.sh";;
    esac
done

# show build info
echo "---------------------"
echo "- Build Information -"
echo "---------------------"
echo "Profile: $PROFILENAME"
echo "Arch: $PROFILEARCH"
echo "Kernel: linux-$KERNEL_FLAVOR"
echo "Zstd level: $ZSTD_LEVEL"
echo "Build command: $BUILD_CMD"

exit 0

# create required directories
mkdir -p "$CACHEDIR" "$OUTDIR"

# create user directories
for dir in Downloads Documents Pictures Videos Music; do
	mkdir -p "$PROFILEDIR/apk/sigma-rootfs/rootfs/etc/skel/$dir"
done

# build sigma rootfs apk
mkdir -p "$REPODIR"
cd "$APKDIR"/sigma-rootfs
tar -zcf rootfs.tar.gz rootfs
export ROOTFS_SHA512="$(sha512sum rootfs.tar.gz)"
abuild -rf -P "$REPODIR"
rm rootfs.tar.gz
cd "$BASEDIR"

# build iso
sudo -E sh build-minirootfs.sh
# sh build-mkimg.sh

# create checksum
cd "$OUTDIR"
sha256sum *.iso > sha256sums
cd "$BASEDIR"

