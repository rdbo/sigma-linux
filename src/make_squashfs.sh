#!/bin/sh

set -e

mkdir -p "$SQUASHFS_DIR"
pkgs="$(cat "$SRC_DIR/pkglist" | sed 's/#.*//g' | tr '\n' ' ')"
echo "Packages: $pkgs"

# Initialize APK database
if [ ! -d "$SQUASHFS_DIR/etc/apk" ]; then
	apk add --initdb -p "$SQUASHFS_DIR"
fi

# Install packages
apk add \
	-p "$SQUASHFS_DIR" \
	--allow-untrusted \
	--no-cache \
	--repositories-file="$REPOS_FILE" \
	-X "$REPO_DIR/apk" \
	$pkgs

# Add repositories file to squashfs
mkdir -p "$SQUASHFS_DIR/etc/apk"
cp "$REPOS_FILE" "$SQUASHFS_DIR/etc/apk/repositories"

# Overwrite package owned files
cat <<- EOF > "$SQUASHFS_DIR/etc/motd"
Welcome to Sigma Linux!
Made by rdbo

To install the system, run the following command: setup-sigma

For more information about the distribution, see:
 - https://github.com/rdbo/sigma-linux
 - https://wiki.alpinelinux.org

EOF

# Create squashfs
rm -f "$SQUASHFS_PATH" # Avoid appending to existing squashfs file
mksquashfs "$SQUASHFS_DIR" "$SQUASHFS_PATH"
