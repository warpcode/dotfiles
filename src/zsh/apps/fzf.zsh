(( $+commands[fzf] )) || return

# Use fzf for history search
source <(fzf --zsh 2>/dev/null)
