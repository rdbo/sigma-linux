# start dbus
pkill -9 dbus-daemon
export DBUS_SESSION_BUS_ADDRESS="$(dbus-daemon --session --print-address --fork)"

# load prefered keyboard layout
KBDLAYOUT_FILE="$HOME/.cache/sigma/kbdlayout"
if [ -f "$KBDLAYOUT_FILE" ]; then
        setxkbmap -layout "$(cat "$KBDLAYOUT_FILE")"
fi

# update background
feh --bg-fill /usr/share/backgrounds/wallpaper.png

# start notification daemon
dunst &

# start topbar modules
dwmblocks &

# start window manager
exec dwm
