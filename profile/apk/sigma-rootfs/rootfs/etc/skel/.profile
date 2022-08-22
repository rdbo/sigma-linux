echo -e "\033[1;36m\
##########
 ##
  ##
   #####
  ##
 ##
##########
"

PS1='\033[1;36m烈\w'
if [ "$(id -u)" = "0" ]; then
	PS1="$PS1 # "
else
	PS1="$PS1 $ "
fi
PS1="$PS1\033[1;37m"

export _JAVA_AWT_WM_NONREPARENTING=1

