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

fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        arg=-sbh;
    else
        arg=-sh;
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@";
    else
        du $arg .[^.]* ./*;
    fi;
}

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
}
