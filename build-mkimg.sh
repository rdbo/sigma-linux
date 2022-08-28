#!/bin/sh

# OBS: This script must be called from 'build.sh'

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

