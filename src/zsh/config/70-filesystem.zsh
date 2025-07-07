# Setup default editor
export EDITOR=nano
if (( $+commands[nvim] )); then
    export EDITOR=nvim
elif (( $+commands[vim] )); then
    export EDITOR=vim
fi

e() {
    if [[ $EDITOR == '' ]]
    then
        echo "\$EDITOR variable is empty"
        exit 1
    fi

    [ "$1" = "" ] && $EDITOR . || $EDITOR "$1"
}


alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# create directory and cd into it
function mkd() {
    mkdir -p "$@" && cd "$@"
}


#######################
# Shortcuts
#######################
alias desktop="cd ~/Desktop"
alias downloads="cd ~/Downloads"
alias docs="cd ~/Documents"
alias dotfiles="cd '$DOTFILES'"
alias nvim.conf="git_clone_and_go 'git@github.com:warpcode/vim-config.git' ~/src/vim-config/"
