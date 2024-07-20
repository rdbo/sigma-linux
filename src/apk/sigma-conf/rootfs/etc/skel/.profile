# show logo
echo
printf "\033[1;36m"
cat /usr/share/sigma/ascii/sigma
echo

# setup vars
. sigma-common
curtty="$(tty | grep tty)"

# setup $PS1
export PS1="\[\033[1;36m\]烈\u@\h:\w \$ \[\033[0;37m\]"

# aliases
alias ls='ls --auto'

# setup gtk theme
export GTK_THEME="Flat-Remix-GTK-Green-Darkest-Solid"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ]; then
	exec dbus-launch river
fi
