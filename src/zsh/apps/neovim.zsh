export NVIM_CONFIG_GIT_URL=git@github.com:warpcode/vim-config.git
export NVIM_CONFIG_PATH=~/src/vim-config/

alias nvim.conf="_git_clone_and_cd $NVIM_CONFIG_GIT_URL $NVIM_CONFIG_PATH"
alias nvim.edit="_nvim_tmux_setup"

function _nvim_tmux_setup() {
    nvim.conf
    _tmux_basic_git "neovim"
    cd -
}
