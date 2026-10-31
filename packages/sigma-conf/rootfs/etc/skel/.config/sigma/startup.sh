#!/bin/sh

. sigma-common

# Give services that D-Bus starts on demand (portals, mako, easyeffects) the compositor's environment
dbus-update-activation-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR

swaybg -m fill -i "$SIGMA_CONFIG_DIR/background" &
# PipeWire normally runs as OpenRC user services; wait for it (easyeffects needs
# it), or start it here on sessions without user services
if [ -d "$XDG_RUNTIME_DIR/openrc" ] && [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/rc/runlevels/default/pipewire" ]; then
	tries=0
	while [ ! -S "$XDG_RUNTIME_DIR/pipewire-0" ] && [ $tries -lt 50 ]; do
		sleep 0.1
		tries=$((tries + 1))
	done
else
	/usr/libexec/pipewire-launcher # Starts pipewire and waits for it to initialize
fi
mako &
waybar &
easyeffects --gapplication-service &
sigma-vkbd --hidden &
sigma-change-kbdlayout -r # Restore last used keyboard layout
xrdb "$HOME/.Xresources" # Setup Xresources

exec <&-
