#!/bin/sh

# OBS: This script must be called from 'build.sh'

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

# setup runtime files
cp "$PROFILEDIR/mkimg.sh" "$BASEDIR/aports/scripts/mkimg.$PROFILENAME.sh"
cp "$PROFILEDIR/genapkovl.sh" "$BASEDIR/aports/scripts/genapkovl-$PROFILENAME.sh"

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

