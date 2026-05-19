[[ -o interactive ]] || return 0
(( $+commands[fzf] )) || return 0

local fzf_init
fzf_init="$(fzf --zsh 2>/dev/null)" || fzf_init=""
if [[ -n "$fzf_init" ]]; then
    source =(print -r -- "$fzf_init")
    return 0
fi

local fzf_plugin="$DOTFILES/vendor/ohmyzsh/plugins/fzf/fzf.plugin.zsh"
[[ -f "$fzf_plugin" ]] || return 1
source "$fzf_plugin"
