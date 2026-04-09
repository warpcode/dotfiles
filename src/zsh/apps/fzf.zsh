(( $+commands[fzf] )) || return

if [[ -o interactive ]]; then
    # Use fzf for history search in an interactive shell
    source <(fzf --zsh 2>/dev/null)
fi
