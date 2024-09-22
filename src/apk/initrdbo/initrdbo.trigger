#!/bin/sh

for dir in "$@"; do
	flavor=${dir##*/}
	release="$(cat "/usr/share/kernel/$flavor/kernel.release")"
	initramfs_path="/boot/initramfs-$flavor"
	if [ -f "$initramfs_path" ]; then
		cp "$initramfs_path" "/boot/initramfs-$flavor.old"
		rm "$initramfs_path"
	fi

	# TODO: use 'xz' as the compressor, currently not working
	initrdbo -k "$release" -z "gzip" "$initramfs_path"
done
