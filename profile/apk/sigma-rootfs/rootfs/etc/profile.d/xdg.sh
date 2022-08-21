export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="$(mktemp -d)"

mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
