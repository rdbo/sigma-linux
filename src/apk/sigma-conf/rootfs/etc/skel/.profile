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
    rc-service --user dbus start
	# exec river
	# exec Hyprland
	# exec dwl -s "sh -c '$SIGMA_CONFIG_DIR/startup.sh'"
	exec niri
	# exec start-cosmic
	# exec mango
fi
