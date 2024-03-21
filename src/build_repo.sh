#!/bin/sh

# NOTE: Run as the build user!

set -e

mkdir -p "$REPO_DIR" "$APKTEMP_DIR"

# Make temporary APK with compressed sources in the cache directory
mkdir -p "$APKTEMP_DIR/sigma-conf/"
cp "$APK_DIR/sigma-conf/APKBUILD" "$APKTEMP_DIR/sigma-conf/"
cd "$APK_DIR/sigma-conf"
tar -czf "$APKTEMP_DIR/sigma-conf/rootfs.tar.gz" rootfs
cd "$APKTEMP_DIR/sigma-conf"
abuild checksum

# Build repository with the local APKs
abuild -rf -P "$REPO_DIR"
