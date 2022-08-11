#!/bin/sh

export PROFILENAME="sigma"
export CACHEDIR="$(pwd)/cache"
export PROFILEDIR="$(pwd)/profile"
export OUTDIR="$(pwd)/iso"
export UNIONFS_SIZE="2G"
export APKLIST="$(sh $PROFILEDIR/apklist.sh)"

mkdir -p "$CACHEDIR" "$OUTDIR"

# setup runtime files
echo "$PROFILENAME" > "$PROFILEDIR/etc/hostname"
cp "$PROFILEDIR/mkimg.sh" "aports/scripts/mkimg.$PROFILENAME.sh"
cp "$PROFILEDIR/genapkovl.sh" "aports/scripts/genapkovl-$PROFILENAME.sh"

# create user directories
for dir in Downloads Documents Pictures Videos Music; do
	mkdir -p "$PROFILEDIR/etc/local.d/rootfs/etc/skel/$dir"
done

# build alpine iso
cd aports/scripts
sh mkimage.sh \
	--tag edge \
	--outdir "$OUTDIR" \
	--arch x86_64 \
	--repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
	--repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
	--repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
	--profile "$PROFILENAME" \
	--workdir "$CACHEDIR"

# create checksum
cd "$OUTDIR"
sha256sum *.iso > sha256sums
cd ..
