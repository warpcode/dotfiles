# Files will be created with these permissions:
# files 644 -rw-r--r--
# dirs  755 drwxr-xr-x
umask 022

#######################
# Easier navigation
#######################
s_name=""
s_exec="cd "

for i in {1..10}; do
    # This may be overkill but covers a lot of traversal
    s_name="${s_name}.."
    s_exec="${s_exec}../"
    alias "${s_name}"="${s_exec}"
done

alias ~="cd ~"
alias -- -="cd -"


#######################
# Shortcuts
#######################
alias desktop="cd ~/Desktop"
alias downloads="cd ~/Downloads"
alias home="cd ${HOME}"
alias cddotfiles="cd ~/.dotfiles"



#######################
# Create
#######################
# create directory and cd into it
function mkcd() {
    mkdir -p "$@" && cd "$@"
}

# Copy w/ progress
cp_p () {
  rsync -WavP --human-readable --progress "$1" "$2"
}


#######################
# Open
#######################
# Opening Shortcuts
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias ofb="open ."
elif [[ `hash gnome-open 2>/dev/null` ]]; then
    alias ofb="gnome-open ."
elif [[ `hash nautilus 2>/dev/null` ]]; then
    alias ofb="nautilus ."
elif [[ `hash dolphin 2>/dev/null` ]]; then
    alias ofb="dolphin ."
fi

#######################
# Open Editor
#######################
function e(){
    if [[ $EDITOR == '' ]]
    then
        echo "\$EDITOR variable is empty"
        exit 1
    fi

    if [ "$1" = "" ] ; then
      exec $EDITOR .
    else
      exec $EDITOR "$1"
    fi
}

