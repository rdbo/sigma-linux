#!/bin/sh

APKS=""

addapk() {
	APKS="$APKS $@"
}

# --------------------
# System

## Firmware
# addapk linux-firmware

## Storage
addapk ntfs-3g

# Admin Tools
addapk sudo doas openssh

# Setup Dependencies
addapk busybox busybox-mdev-openrc openssl sfdisk mdadm lvm2 cryptsetup blkid xfsprogs e2fsprogs btrfs-progs dosfstools farbfeld musl-dev

# Library Dependencies
addapk libx11-dev libxft-dev libxinerama-dev libxrandr-dev imlib2-dev harfbuzz-dev freetype-dev libxtst-dev libxcb-dev

## Development Tools
addapk bash tcc mold make perl

## Tools for building this distribuition
# addapk git alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso squashfs-tools sudo mtools dosfstools grub-efi

# --------------------
# Xorg

## Xorg Server
addapk dbus dbus-openrc xorg-server eudev udev udev-init-scripts udev-init-scripts-openrc

## Xorg Video
addapk xf86-video-intel xf86-video-amdgpu xf86-video-vesa xf86-video-vboxvideo xf86-video-vmware xf86-video-modesetting xf86-video-qxl xf86-video-nouveau mesa mesa-egl

## Xorg Input
addapk xf86-input-libinput xf86-input-evdev xf86-input-synaptics

## Xorg Tools
addapk xrandr xsetroot setxkbmap xprop xclip xev xkill

## Display Manager
# addapk lightdm lightdm-gtk-greeter

## Window Manager
# addapk bspwm

## Hotkey Daemon
# addapk sxhkd

## Compositor
# addapk picom

## Cursor Theme
addapk adwaita-icon-theme

## Icon Theme
# addapk papirus-icon-theme

## Appearance Changer
# addapk lxappearance

## Screenshot Tool
addapk maim

## Screen Lock
# addapk i3lock

# --------------------
# Audio 

## Audio Server
addapk pipewire pipewire-alsa pipewire-pulse

## Audio Tools
addapk pulsemixer pulseaudio-ctl wireplumber

# --------------------
# Network

## Network Daemon
addapk iwd

## VPN Tools
addapk wireguard-tools openvpn

# --------------------
# Bluetooth
addapk bluez

# --------------------
# Applications

## Terminal Emulator
# addapk alacritty

## Status Bar
# addapk polybar

## Text Editor
addapk vim helix

# File Explorer
addapk xfe

# Notification Daemon
addapk dunst

## App Launcher
# addapk rofi

## Image Viewer
addapk feh nsxiv

# Audio/Video Player
addapk mpv

# Password Manager
addapk gnupg pass

## Web Browser
# addapk firefox
addapk surf

## Office Tools
# addapk libreoffice
addapk poppler poppler-utils
addapk groff
addapk sc-im

## PDF Viewer
addapk zathura zathura-pdf-mupdf

## Graphics Tools
# addapk gimp
# addapk inkscape
addapk imagemagick
addapk ffmpeg

# IRC Chat
addapk weechat

# Mail Client
addapk neomutt

# RSS Feed
addapk newsboat

# --------------------
# Misc

## Fonts
addapk font-dejavu

## Utilities
addapk mandoc ncurses file p7zip tar gzip xz wget curl entr

## Documentation
# addapk man-pages ntfs-3g-doc sudo-doc doas-doc openssh-doc busybox-doc openssl-doc lvm2-doc cryptsetup-doc xfsprogs-doc e2fsprogs-doc btrfs-progs-doc dosfstools-doc farbfeld-doc libx11-doc libxft-doc libxinerama-doc libxrandr-doc harfbuzz-doc freetype-doc libxtst-doc libxcb-doc bash-doc tcc-doc mold-doc make-doc git-doc dbus-doc xorg-server-doc eudev-doc xrandr-doc xsetroot-doc setxkbmap-doc xprop-doc xclip-doc xev-doc xkill-doc maim-doc pipewire-doc pulseaudio-ctl-doc wireguard-tools-doc openvpn-doc bluez-doc vim-doc xfe-doc dunst-doc nsxiv-doc mpv-doc gnupg-doc pass-doc surf-doc poppler-doc groff-doc sc-im-doc zathura-doc imagemagick-doc ffmpeg-doc mandoc-doc file-doc p7zip-doc tar-doc gzip-doc xz-doc wget-doc curl-doc

# --------------------
# Show Packages

echo $APKS
