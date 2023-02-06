echo -e "\033[1;36m\
##########
 ##
  ##
   #####
  ##
 ##
##########
"

# setup $PS1
PS1='\033[1;36m烈\w'
if [ "$(id -u)" = "0" ]; then
	PS1="$PS1 # "
else
	PS1="$PS1 $ "
fi
PS1="$PS1\033[1;37m"

# fix for Java GUI applications
export _JAVA_AWT_WM_NONREPARENTING=1

# start window manager on tty1
if [ "$(tty)" = "/dev/tty1" ]; then
	startx
fi
