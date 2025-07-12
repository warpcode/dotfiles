export NVIM_CONFIG_GIT_URL=git@github.com:warpcode/vim-config.git
export NVIM_CONFIG_PATH=~/src/vim-config/

alias nvim.conf="git_clone_and_cd $NVIM_CONFIG_GIT_URL $NVIM_CONFIG_PATH"
alias nvim.edit="nvim.conf; e .; cd -"

function _nvim_tmux_setup() {
    nvim.conf
    tmux att -t neovim ||
        tmux \
        new -s neovim -n editor \; \
        send-keys 'e .' C-m\; \
        \
        neww -n git \; \
        send-keys 'lazygit' C-m\; \
        \
        selectw -t editor
}
