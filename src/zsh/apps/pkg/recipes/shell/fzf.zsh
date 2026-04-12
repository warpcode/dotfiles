pkg.recipe.define fzf \
    package="fzf" \
    managers="apt dnf pacman brew"

pkg.recipe.fzf.init() {
    (( $+commands[fzf] )) || return 0
    [[ -o interactive ]] || return 0

    local fzf_init
    fzf_init="$(fzf --zsh 2>/dev/null)" || fzf_init=""
    if [[ -n "$fzf_init" ]]; then
        source =(print -r -- "$fzf_init")
        return 0
    fi

    local fzf_plugin="$DOTFILES/vendor/ohmyzsh/plugins/fzf/fzf.plugin.zsh"
    [[ -f "$fzf_plugin" ]] || return 1
    source "$fzf_plugin"
}
