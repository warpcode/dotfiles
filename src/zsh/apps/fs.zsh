# Have on "open alias" on par with MacOS
if [[ ! "$OSTYPE" =~ ^darwin ]]; then
    open() {
        xdg-open ${@:-.}
    }
fi

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

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
