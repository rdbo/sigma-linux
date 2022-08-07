PS1='\033[1;36m烈\w'
if [ "$(id -u)" = "0" ]; then
	PS1="$PS1 # "
else
	PS1="$PS1 $ "
fi
PS1="$PS1\033[1;37m"
