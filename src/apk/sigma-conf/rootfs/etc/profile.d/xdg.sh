export XDG_RUNTIME_DIR="/tmp/run-$USER-$(id -u)"

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
	mkdir -m 700 -p "$XDG_RUNTIME_DIR"
fi
