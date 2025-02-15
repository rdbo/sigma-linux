# show logo
echo
printf "\033[1;36m"
cat /usr/share/sigma/ascii/sigma
echo

# setup vars
. sigma-common

# setup $PROMPT
export PROMPT="%B%F{cyan}烈%n@%m:%~ %(#.#.\$) %b%F{white}"

# setup gtk theme
export GTK_THEME="Flat-Remix-GTK-Green-Darkest-Solid"

# fix for java apps
export _JAVA_AWT_WM_NONREPARENTING=1

# aliases
alias ls="ls --color=auto"

# keys
bindkey "^[[3~" delete-char
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
