KBDLAYOUT_FILE="$HOME/.cache/sigma/kbdlayout"
if [ -f "$KBDLAYOUT_FILE" ]; then
        setxkbmap -layout "$(cat "$KBDLAYOUT_FILE")"
fi
feh --bg-fill /usr/share/backgrounds/wallpaper.png
dunst &
dwmblocks &
dbus-run-session -- dwm
