#!/bin/sh

. sigma-common

# Give services that D-Bus starts on demand (portals, mako, easyeffects) the compositor's environment
dbus-update-activation-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR

swaybg -m fill -i "$SIGMA_CONFIG_DIR/background" &
/usr/libexec/pipewire-launcher # Starts pipewire and waits for it to initialize
mako &
waybar &
easyeffects --gapplication-service &
sigma-vkbd --hidden &
sigma-change-kbdlayout -r # Restore last used keyboard layout
xrdb "$HOME/.Xresources" # Setup Xresources

exec <&-
