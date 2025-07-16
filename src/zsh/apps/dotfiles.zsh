alias dotfiles.conf="cd '$DOTFILES'"
alias dotfiles.edit="_dotfiles_tmux_setup"

function _dotfiles_tmux_setup() {
    dotfiles.conf
    _tmux_basic_git "dotfiles"
    cd -
}
