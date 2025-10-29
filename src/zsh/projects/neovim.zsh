# Neovim configuration management
# Provides aliases to clone and manage neovim config repository

: "${NVIM_CONFIG_GIT_URL:=git@github.com:warpcode/vim-config.git}"
: "${NVIM_CONFIG_PATH:=~/src/vim-config/}"

alias nvim.cd="_git_clone_and_cd $NVIM_CONFIG_GIT_URL $NVIM_CONFIG_PATH"
alias nvim.edit="(nvim.cd && _tmux_basic_git "neovim")"


