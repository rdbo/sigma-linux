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

# Other
alias ls="ls --color=auto"

# create sigma cache folder
mkdir -p "$HOME/.cache/sigma"

# setup gtk theme
export GTK_THEME="Flat-Remix-GTK-Green-Darkest-Solid"

# setup rust stuff
. "$HOME/.cargo/env"

# setup go stuff
export PATH="$HOME/go/bin:$PATH"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ]; then
#	exec dbus-launch river
	exec dbus-launch Hyprland
fi
