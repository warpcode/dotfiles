# Attempt to find the location of dotfiles
DOTFILES_BASHRC=$(readlink -f ~/.bashrc)
if [[ "$DOTFILES_BASHRC" != "$HOME/.bashrc" ]]
then
    DOTFILES_DIR=$(dirname "$DOTFILES_BASHRC")
    IS_DOTFILES=1
else
    DOTFILES_DIR="$HOME"
    IS_DOTFILES=0
fi

if [[ "$IS_DOTFILES" == "1" ]]
then
    # Load in the dotfiles files
    for file in $DOTFILES_DIR/bashrc/{path,prompt,exports,aliases,functions,extra}.sh; do
        [ -e "$file" ] && source "$file";
    done;
    unset file;
fi

# Load additional custom files
# * ~/.bash_aliases can be used for additional aliases.
# * ~/.bash_path can be used to extend `$PATH`.
# * ~/.bash_extra can be used for other settings you don’t want to commit.
for file in ~/.bash_{path,prompt,exports,aliases,functions,extra}; do
	[ -e "$file" ] && source "$file";
done;
unset file;
