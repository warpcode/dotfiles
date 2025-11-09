(( $+commands[direnv] )) || return

# Integrate direnv hooks
eval "$(direnv hook zsh)"