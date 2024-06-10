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

# sigma-st
if ! is_apk_indexed sigma-st; then
	cp -r "$APK_DIR/sigma-st/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-st"
	abuild checksum

	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-st', already indexed"
fi

# sigma-vt323
if ! is_apk_indexed sigma-vt323; then
	cp -r "$APK_DIR/sigma-vt323/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-vt323"
	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-vt323', already indexed"
fi

# sigma-wvkbd
_target_arch="$TARGET_ARCH"
unset TARGET_ARCH # Fix for linker failing to build
# TODO: Reconsider name for variable 'TARGET_ARCH'

if ! is_apk_indexed sigma-wvkbd; then
	cp -r "$APK_DIR/sigma-wvkbd/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-wvkbd"
	abuild checksum

	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-wvkbd', already indexed"
fi
TARGET_ARCH="$_target_arch"

# sigma-flat-remix-gtk
if ! is_apk_indexed sigma-flat-remix-gtk; then
	cp -r "$APK_DIR/sigma-flat-remix-gtk/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-flat-remix-gtk"
	abuild -rf -P "$REPO_DIR"
else
	echo "[*] Skipped building APK 'sigma-flat-remix-gtk', already indexed"
fi
