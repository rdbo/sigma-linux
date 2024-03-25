#!/bin/sh

# NOTE: Run as the build user!

set -e

mkdir -p "$REPO_DIR" "$APKTEMP_DIR"

# Get existing APKs in repo (if any)
apklist="$(find cache/repo/ -name "*.apk" | sed 's|.*/||')"
is_apk_indexed() {
	printf "%s" "$apklist" | tr ' ' '\n' | grep "^$1-" > /dev/null
	return $?
}

# sigma-conf
if ! is_apk_indexed sigma-conf; then
	# Make temporary APK with compressed sources in the cache directory
	mkdir -p "$APKTEMP_DIR/sigma-conf/"
	cp "$APK_DIR/sigma-conf/APKBUILD" "$APKTEMP_DIR/sigma-conf/"
	cd "$APK_DIR/sigma-conf"
	tar -czf "$APKTEMP_DIR/sigma-conf/rootfs.tar.gz" rootfs
	cd "$APKTEMP_DIR/sigma-conf"
	abuild checksum

	# build apk and index it in the repository
	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-conf', already indexed"
fi

# sigma-river
if ! is_apk_indexed sigma-river; then
	mkdir -p "$APKTEMP_DIR/sigma-river/"
	cp "$APK_DIR/sigma-river/APKBUILD" "$APKTEMP_DIR/sigma-river/"
	cd "$APKTEMP_DIR/sigma-river"
	## clone repository and archive it
	if [ ! -d river ]; then
		git clone --depth 1 https://codeberg.org/river/river river
		cd river
		git submodule update --init
		cd ..
	else
		cd river
		git pull origin
		cd ..
	fi
	tar -czf river.tar.gz river
	abuild checksum

	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-river', already indexed"
fi

# sigma-firacode-nerd
if ! is_apk_indexed sigma-firacode-nerd; then
	cp -r "$APK_DIR/sigma-firacode-nerd/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-firacode-nerd"
	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-firacode-nerd', already indexed"
fi

# sigma-sent
if ! is_apk_indexed sigma-sent; then
	mkdir -p "$APKTEMP_DIR/sigma-sent/"
	cp "$APK_DIR/sigma-sent/APKBUILD" "$APKTEMP_DIR/sigma-sent/"
	cd "$APK_DIR/sigma-sent"
	tar -czf "$APKTEMP_DIR/sigma-sent/sent.tar.gz" sent
	cd "$APKTEMP_DIR/sigma-sent"
	abuild checksum

	# build apk and index it in the repository
	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-sent', already indexed"
fi

# sigma-helix
if ! is_apk_indexed sigma-helix; then
	cp -r "$APK_DIR/sigma-helix/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-helix"
	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-helix', already indexed"
fi
