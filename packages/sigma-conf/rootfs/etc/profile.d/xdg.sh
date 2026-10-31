export XDG_RUNTIME_DIR="/tmp/run-$USER-$(id -u)"

mkdir -m 700 "$XDG_RUNTIME_DIR" 2>/dev/null

# /tmp is shared: refuse a directory (or symlink) that another user created first
if [ -L "$XDG_RUNTIME_DIR" ] || [ ! -O "$XDG_RUNTIME_DIR" ]; then
	echo "xdg.sh: $XDG_RUNTIME_DIR is not owned by $USER, leaving XDG_RUNTIME_DIR unset" >&2
	unset XDG_RUNTIME_DIR
else
	chmod 700 "$XDG_RUNTIME_DIR"
fi
