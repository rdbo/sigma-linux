# show logo
echo
printf "\033[1;36m"
cat /usr/share/sigma/ascii/sigma
echo

# setup vars
. sigma-common
curtty="$(tty | grep tty)"

# setup $PS1
PS1='\033[1;36m烈\w'
if [ "$(id -u)" = "0" ]; then
	PS1="$PS1 # "
else
	PS1="$PS1 $ "
fi
export PS1="$PS1\033[0;37m"

# create sigma cache folder
mkdir -p "$HOME/.cache/sigma"

# start window manager on tty1
if [ "$curtty" = "/dev/tty1" ]; then
	exec dbus-launch river
fi
