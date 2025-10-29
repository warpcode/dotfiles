# Register fzf package mappings using the new API
_installer_package "default" fzf

(( $+commands[fzf] )) || return

# Use fzf for history search
source <(fzf --zsh 2>/dev/null)
