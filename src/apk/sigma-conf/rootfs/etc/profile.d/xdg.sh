if [ -z "$XDG_RUNTIME_DIR" ]; then
	export XDG_RUNTIME_DIR="/tmp/run-$USER"

	rm -rf "$XDG_RUNTIME_DIR"
	mkdir -m 700 -p "$XDG_RUNTIME_DIR"
fi
