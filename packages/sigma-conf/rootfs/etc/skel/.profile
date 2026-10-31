# show logo (interactive shells only: openrc-user also runs this as a login shell)
case $- in
*i*)
	echo
	printf "\033[1;36m"
	cat /usr/share/sigma/ascii/sigma
	echo
	;;
esac

# setup vars
. sigma-common
curtty="$(tty | grep tty)"

# session bus of the dbus OpenRC user service, for shells outside the graphical session too
if [ -S "$XDG_RUNTIME_DIR/bus" ] && [ -r /etc/user/conf.d/dbus ]; then
	. /etc/user/conf.d/dbus
fi

# setup $PS1
PS1="\[\033[1;36m\]烈\u@\h:\w"
if [ "$(id -u)" = "0" ]; then
	PS1="$PS1 #"
else
	PS1="$PS1 \$"
fi
export PS1="$PS1 \[\033[0;37m\]"

# setup gtk theme
export GTK_THEME="Flat-Remix-GTK-Green-Darkest-Solid"

# fix for java apps
export _JAVA_AWT_WM_NONREPARENTING=1

# ruby
export GEM_HOME="$HOME/.local/share/gem"

# aliases
alias ls="ls --color=auto"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ] && [ $(id -u) -ne 0 ]; then
	# exec sigma-session river
	# exec sigma-session Hyprland
	# exec sigma-session dwl -s "sh -c '$SIGMA_CONFIG_DIR/startup.sh'"
	# exec sigma-session niri
	# exec sigma-session start-cosmic
	exec sigma-session mango
fi
