#!/bin/sh

for dir in "$@"; do
	flavor=${dir##*/}
	release="$(cat "/usr/share/kernel/$flavor/kernel.release")"
	initramfs_path="/boot/initramfs-$flavor"
	if [ -e "$initramfs_path" ]; then
		cp -r "$initramfs_path" "/boot/initramfs-$flavor.old"
		rm -r "$initramfs_path"
	fi

	initrdbo -k "$release" "$initramfs_path"
done
