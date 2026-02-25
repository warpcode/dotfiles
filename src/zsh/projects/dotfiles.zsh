alias df.cd="cd '$DOTFILES'"
alias df.edit="_dotfiles_tmux_setup"

function _dotfiles_tmux_setup() {
    df.cd
    _tmux_basic_git "dotfiles"
    cd -
}

# Install dotfiles bootstrap to ~/.zshrc
function dotfiles.setup() {
    dotfiles.setup.zshrc
    dotfiles.setup.submodules

    events.trigger 'dotfiles.setup'
}

function dotfiles.setup.zshrc() {
    local zshrc=~/.zshrc
    [[ -L "$zshrc" && ! -e "$zshrc" ]] && rm "$zshrc"
    [[ ! -e "$zshrc" ]] && touch "$zshrc"
    chmod 0600 "$zshrc"
    config.markers.replace "$zshrc" '# BEGIN dotfiles' '# END dotfiles' "source '$DOTFILES/src/zsh/init.zsh'"
}

function dotfiles.setup.submodules() {
    (
        df.cd
        local submodule_status=$(git submodule status 2>/dev/null)
        if [[ -n "$submodule_status" ]]; then
            git submodule update --init --remote --recursive
        fi
    )
}

