alias df.cd="cd '$DOTFILES'"
alias df.edit="_dotfiles_tmux_setup"

function _dotfiles_tmux_setup() {
    df.cd
    _tmux_basic_git "dotfiles"
    cd -
}

# Install dotfiles bootstrap to ~/.zshrc
function dotfiles.setup() {
    dotfiles.setup.submodules || return 1
    dotfiles.setup.zshrc || return 1
    events.trigger 'dotfiles.setup.first'
    events.trigger 'dotfiles.setup'
}

function dotfiles.setup.zshrc() {
    local zshrc=~/.zshrc
    [[ -L "$zshrc" && ! -e "$zshrc" ]] && rm "$zshrc"
    [[ ! -e "$zshrc" ]] && touch "$zshrc"
    chmod 0600 "$zshrc"
    config.block "$zshrc" '# BEGIN dotfiles' '# END dotfiles' "source '$(fs.dotfiles.path "src/zsh/init.zsh")'"
}

function dotfiles.setup.submodules() {
    (
        df.cd || return 1
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git submodule update --init --remote --recursive || return 1
        fi
    )
}
