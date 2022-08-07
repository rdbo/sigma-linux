#!/bin/sh

export PROFILENAME="sigma"
export CACHEDIR="$(pwd)/cache"
export PROFILEDIR="$(pwd)/profile"
export OUTDIR="$(pwd)/iso"
export APKLIST="$(sh $PROFILEDIR/apklist.sh)"

mkdir -p "$CACHEDIR" "$OUTDIR"

echo "$PROFILENAME" > "$PROFILEDIR/etc/hostname"
cp "$PROFILEDIR/mkimg.sh" "aports/scripts/mkimg.$PROFILENAME.sh"
cp "$PROFILEDIR/genapkovl.sh" "aports/scripts/genapkovl-$PROFILENAME.sh"

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

cd "$OUTDIR"
sha256sum * > sha256sums
cd ..
