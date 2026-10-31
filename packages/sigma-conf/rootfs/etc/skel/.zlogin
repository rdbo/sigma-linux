# setup vars
. sigma-common
curtty="$(tty | grep tty)"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ]; then
	exec sigma-session river
	# exec sigma-session Hyprland
	# exec sigma-session dwl -s "sh -c '$SIGMA_CONFIG_DIR/startup.sh'"
fi
