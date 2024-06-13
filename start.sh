#!/bin/sh

qemu-system-x86_64 \
	-enable-kvm \
	-smp 4 \
	-m 2048 \
	-cdrom cache/sigma-linux.iso \
	$@
