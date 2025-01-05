#!/bin/sh

. sigma-common

swaybg -m fill -i "$SIGMA_CONFIG_DIR/background" &
/usr/libexec/pipewire-launcher # Starts pipewire and waits for it to initialize
mako &
waybar &
easyeffects --gapplication-service &
sigma-vkbd --hidden &

exec <&-
