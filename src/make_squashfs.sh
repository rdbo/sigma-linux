#!/bin/sh

set -e

mkdir -p "$SQUASHFS_DIR"
pkgs="$(cat "$SRC_DIR/pkglist" | tr '\n' ' ')"
echo "Packages: $pkgs"

# Initialize APK database
apk add --initdb -p "$SQUASHFS_DIR"

apk add \
	-p "$SQUASHFS_DIR" \
	--allow-untrusted \
	--no-cache \
	--repositories-file="$REPOS_FILE" \
	$pkgs

# Create squashfs
mksquashfs "$SQUASHFS_DIR" "$SQUASHFS_PATH"
