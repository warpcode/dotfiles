# Register fzf package mappings using the new API
_installer_package "github" fzf "junegunn/fzf@v0.66.1"

(( $+commands[fzf] )) || return

# Use fzf for history search
source <(fzf --zsh 2>/dev/null)
