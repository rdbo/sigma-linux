#!/bin/sh

export PROFILENAME="sigma"
export PROFILEVER="2.1"
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

