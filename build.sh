#!/bin/sh

export PROFILENAME="sigma"
export PROFILEVER="3.0"
export PROFILEURL="https://github.com/rdbo/sigma-linux"
export PROFILEARCH="$(uname -m)"
export BASEDIR="$(pwd)"
export CACHEDIR="$BASEDIR/cache"
export PROFILEDIR="$BASEDIR/profile"
export APKDIR="$PROFILEDIR/apk"
export OUTDIR="$BASEDIR/out"
export APKLIST="$(sh $PROFILEDIR/apklist.sh)"
export REPODIR="$PROFILEDIR/repo"
export BUILD_CMD="sudo -E sh build-chroot.sh"
export KERNEL_FLAVOR="lts"
export ZSTD_LEVEL="22"
export IGNORE_SIGMA_ROOTFS="no"

# parse args
getval() {
    echo $1 | cut -d '=' -f 2
}

for arg in $@; do
    case $arg in
        # quick build
        "-q") export ZSTD_LEVEL="9";;

        # custom arch
        "-a="*) export PROFILEARCH="$(getval $arg)";;

        # custom kernel flavor
        "-k="*) export KERNEL_FLAVOR="$(getval $arg)";;

        # legacy build
        "-l") export BUILD_CMD="sh build-mkimg.sh";;

        # ignore sigma-rootfs (faster build for testing)
        "-i") export IGNORE_SIGMA_ROOTFS="yes";;
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
echo "Ignore Sigma RootFS? $IGNORE_SIGMA_ROOTFS"
echo "Build command: $BUILD_CMD"
echo "---------------------"

# create required directories
echo "[*] Setting up directories..."
mkdir -p "$CACHEDIR" "$OUTDIR"

if [ "$IGNORE_SIGMA_ROOTFS" != "yes" ]; then
    # create user directories
    for dir in Downloads Documents Pictures Videos Music; do
    	mkdir -p "$PROFILEDIR/apk/sigma-rootfs/rootfs/etc/skel/$dir"
    done

    # build sigma rootfs apk
    echo "[*] Creating 'sigma-rootfs'..."
    mkdir -p "$REPODIR"
    cd "$APKDIR"/sigma-rootfs
    tar -zcf rootfs.tar.gz rootfs
    export ROOTFS_SHA512="$(sha512sum rootfs.tar.gz)"
    abuild -rf -P "$REPODIR"
    rm rootfs.tar.gz
    cd "$BASEDIR"
fi

# build iso
echo "[*] Starting build command: $BUILD_CMD"
$BUILD_CMD
echo "[*] Build complete"

# create checksum
cd "$OUTDIR"
sha256sum *.iso > sha256sums
cd "$BASEDIR"
echo "[*] Output files at: $OUTDIR"
