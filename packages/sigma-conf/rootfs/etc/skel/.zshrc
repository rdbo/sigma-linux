# show logo
echo
printf "\033[1;36m"
cat /usr/share/sigma/ascii/sigma

# setup history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY

# keys
bindkey "^[[3~" delete-char
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

bindkey "^[[1;5C" forward-word
bindkey "^W" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^B" backward-word

bindkey -r '^J'

# setup prompt
eval "$(starship init zsh)"
