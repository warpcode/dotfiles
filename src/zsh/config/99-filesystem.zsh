# Setup default editor
export EDITOR=nano
if which nvim >/dev/null 2>&1; then
    export EDITOR=nvim
elif which vim >/dev/null 2>&1; then
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

# Have on "open alias" on par with MacOS
if [[ ! "$OSTYPE" =~ ^darwin ]]; then
    open() {
        xdg-open ${@:-.}
    }
fi

# create directory and cd into it
function mkd() {
    mkdir -p "$@" && cd "$@"
}

if [[ "$OSTYPE" =~ ^darwin ]]
then
    # Change working directory to the top-most Finder window location
    function cdfinder() {
    	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
    }
fi

#######################
# Shortcuts
#######################
alias desktop="cd ~/Desktop"
alias downloads="cd ~/Downloads"
alias dotf="cd '$DOTFILES'"