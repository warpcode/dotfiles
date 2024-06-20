(( $+commands[fzf] )) || return

# Use fzf for history search
source <(fzf --zsh)
