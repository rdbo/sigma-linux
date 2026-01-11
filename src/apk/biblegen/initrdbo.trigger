#!/bin/sh

for dir in "$@"; do
	flavor=${dir##*/}
	release="$(cat "/usr/share/kernel/$flavor/kernel.release")"
	initramfs_path="/boot/initramfs-$flavor"
	if [ -e "$initramfs_path" ]; then
		datetime="$(date "+%Y-%m-%d_%H-%M-%S")"
		cp -r "$initramfs_path" "/boot/initramfs-$flavor.old_$datetime"
		rm -r "$initramfs_path"
	fi

	initrdbo -k "$release" "$initramfs_path"
done
