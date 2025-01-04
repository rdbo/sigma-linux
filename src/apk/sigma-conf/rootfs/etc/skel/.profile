# show logo
echo
printf "\033[1;36m"
cat /usr/share/sigma/ascii/sigma
echo

# setup vars
. sigma-common
curtty="$(tty | grep tty)"

# setup $PS1
PS1="\[\033[1;36m\]烈\u@\h:\w"
if [ "$(id -u)" = "0" ]; then
	PS1="$PS1 #"
else
	PS1="$PS1 \$"
fi
export PS1="$PS1 \[\033[0;37m\]"

# other
alias ls="ls --color=auto"

# create sigma cache folder
mkdir -p "$HOME/.cache/sigma"

# setup gtk theme
export GTK_THEME="Flat-Remix-GTK-Green-Darkest-Solid"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ]; then
	exec dbus-launch river
	# exec dbus-launch Hyprland
	# exec dbus-launch dwl -s "sh -c '$SIGMA_CONFIG_DIR/startup.sh'"
fi
