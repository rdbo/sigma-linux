#!/bin/sh

# NOTE: Run as the build user!

set -e

mkdir -p "$REPO_DIR" "$APKTEMP_DIR"

# sigma-conf
## Make temporary APK with compressed sources in the cache directory
mkdir -p "$APKTEMP_DIR/sigma-conf/"
cp "$APK_DIR/sigma-conf/APKBUILD" "$APKTEMP_DIR/sigma-conf/"
cd "$APK_DIR/sigma-conf"
tar -czf "$APKTEMP_DIR/sigma-conf/rootfs.tar.gz" rootfs
cd "$APKTEMP_DIR/sigma-conf"
abuild checksum

# sigma-river
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

# sigma-firacode-nerd
cp -r "$APK_DIR/sigma-firacode-nerd/" "$APKTEMP_DIR/"

# Build repository with the local APKs
cd "$APKTEMP_DIR/sigma-conf"
abuild -rf -P "$REPO_DIR"

cd "$APKTEMP_DIR/sigma-river"
abuild -rf -P "$REPO_DIR"

cd "$APKTEMP_DIR/sigma-firacode-nerd"
abuild -rf -P "$REPO_DIR"
