alias df.cd="cd '$DOTFILES'"
alias df.edit="_dotfiles_tmux_setup"

function _dotfiles_tmux_setup() {
    df.cd
    _tmux_basic_git "dotfiles"
    cd -
}
