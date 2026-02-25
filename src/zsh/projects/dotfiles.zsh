alias df.cd="cd '$DOTFILES'"
alias df.edit="_dotfiles_tmux_setup"

function _dotfiles_tmux_setup() {
    df.cd
    _tmux_basic_git "dotfiles"
    cd -
}

# Install dotfiles bootstrap to ~/.zshrc
function dotfiles.install() {
    dotfiles.install.zshrc
}

function dotfiles.install.zshrc() {
    local zshrc=~/.zshrc
    [[ -L "$zshrc" && ! -e "$zshrc" ]] && rm "$zshrc"
    [[ ! -e "$zshrc" ]] && touch "$zshrc"
    chmod 0600 "$zshrc"
    config.markers.replace "$zshrc" '# BEGIN dotfiles' '# END dotfiles' "source '$DOTFILES/src/zsh/init.zsh'"
}
