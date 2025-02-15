# setup vars
. sigma-common
curtty="$(tty | grep tty)"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ]; then
	exec dbus-launch river
	# exec dbus-launch Hyprland
	# exec dbus-launch dwl -s "sh -c '$SIGMA_CONFIG_DIR/startup.sh'"
fi
