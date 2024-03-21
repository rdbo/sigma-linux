#!/bin/sh

set -e

mkdir -p "$SQUASHFS_DIR"
pkgs="$(cat "$SRC_DIR/pkglist" | sed 's/#.*//g' | tr '\n' ' ')"
echo "Packages: $pkgs"

# Initialize APK database
if [ ! -d "$SQUASHFS_DIR/etc/apk" ]; then
	apk add --initdb -p "$SQUASHFS_DIR"
fi

apk add \
	-p "$SQUASHFS_DIR" \
	--allow-untrusted \
	--no-cache \
	--repositories-file="$REPOS_FILE" \
	-X "$REPO_DIR/apk" \
	$pkgs

# Create squashfs
rm -f "$SQUASHFS_PATH" # Avoid appending to existing squashfs file
mksquashfs "$SQUASHFS_DIR" "$SQUASHFS_PATH"
