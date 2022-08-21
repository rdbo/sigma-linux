#!/bin/sh

export PROFILENAME="sigma"
export PROFILEVER="2.0"
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

# download/update 'aports' repository
if [ ! -d "$BASEDIR"/aports ]; then
	git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git
else
	cd "$BASEDIR"/aports
	git fetch
	cd "$BASEDIR"
fi

# create required directories
mkdir -p "$CACHEDIR" "$OUTDIR"

# setup runtime files
echo "$PROFILENAME" > "$PROFILEDIR/etc/hostname"
cp "$PROFILEDIR/mkimg.sh" "aports/scripts/mkimg.$PROFILENAME.sh"
cp "$PROFILEDIR/genapkovl.sh" "aports/scripts/genapkovl-$PROFILENAME.sh"

# create user directories
for dir in Downloads Documents Pictures Videos Music; do
	mkdir -p "$PROFILEDIR/etc/local.d/rootfs/etc/skel/$dir"
done

# build sigma rootfs apk
mkdir -p "$REPODIR"
cd "$APKDIR"/sigma-rootfs
tar -zcf rootfs.tar.gz rootfs
export ROOTFS_SHA512="$(sha512sum rootfs.tar.gz)"
abuild -rf -P "$REPODIR"
rm rootfs.tar.gz
cd "$BASEDIR"

# build alpine iso
cd "$BASEDIR"/aports/scripts
sh mkimage.sh \
	--tag edge \
	--outdir "$OUTDIR" \
	--arch "$PROFILEARCH" \
        --repository "$REPODIR/apk" \
	--repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
	--repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
	--repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
	--profile "$PROFILENAME" \
	--workdir "$CACHEDIR"

# create checksum
cd "$OUTDIR"
sha256sum *.iso > sha256sums
cd "$BASEDIR"

