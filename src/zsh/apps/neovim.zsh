export NVIM_CONFIG_GIT_URL=git@github.com:warpcode/vim-config.git
export NVIM_CONFIG_PATH=~/src/vim-config/

alias nvim.conf="git_clone_and_cd $NVIM_CONFIG_GIT_URL $NVIM_CONFIG_PATH"
alias nvim.edit="nvim.conf; e .; cd -"
