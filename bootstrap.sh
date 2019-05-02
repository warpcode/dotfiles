#!/usr/bin/env bash

if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

# header display
function e_header()   { echo -e "\033[1m$@\033[0m"; }

e_header "Installing Dotfiles"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    echo "SOURCE '$SOURCE' is an absolute symlink to '$TARGET'"
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    echo "SOURCE '$SOURCE' is a relative symlink to '$TARGET' (relative to '$DIR')"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
DOTFILESRDIR="$( dirname "$SOURCE" )"
DOTFILESDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "Dotfiles Directory is : $DOTFILESDIR"

# echo "This script requires sudo permissions."
# echo "If prompted, please enter your password"
# # Ask for the administrator password upfront
# sudo -v
#
# # Keep-alive: update existing `sudo` time stamp until `.osx` has finished
# while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

e_header "Running Installer Procedures"
#required settings to detect files properly in the process function
shopt -s dotglob
shopt -s nullglob

files=("$DOTFILESDIR/install/*")
for file in ${files[@]}; do
    echo "$file"
    source "$file"
done

function symlink_file()
{
    if [[ $1 == '' ]]
    then
        echo "No Source specified"
        exit 1
    fi

    # Check to make sure there's no programmer error
    if [[ ! -e "$DOTFILESDIR/$1" ]]
    then
        return
    fi

    echo " - $1"

    SOURCE="$DOTFILESDIR/$1"
    DESTINATION="$HOME/$1"
    if [[ $2 != '' ]]
    then
        DESTINATION="$2"
    fi

    # Grab the real path of a file
    CURRENTFILE=$(readlink -f "$DESTINATION")
    # Grab a timestamp for file renaming
    CURRENTDATE=$(date "+%Y-%m-%d %H:%M:%S")

    # Backup files that are not a symlink to dotfiles version
    if [[ -e "$DESTINATION" ]]
    then
        if [[ "$CURRENTFILE" != "$SOURCE" ]]
        then
            mv "$DESTINATION" "$DESTINATION.$CURRENTDATE.bak"
        fi
    fi

    # Setup the symlink if not created or because previous file was backed up
    if [[ ! -e "$DESTINATION" ]]
    then
        ln -s "$SOURCE" "$DESTINATION"
    fi
}

e_header "Processing Symlnks"
symlink_file ".tmux.conf"
symlink_file ".bash_profile"
symlink_file ".bashrc"
symlink_file ".gitignore_global"
symlink_file ".screenrc"
symlink_file "vendor/warpcode.vim-config/.vimrc" "$HOME/.vimrc"
symlink_file ".Xdefaults"

e_header "Completed"
