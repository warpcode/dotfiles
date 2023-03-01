# Attempt to find the location of dotfiles
RC_FILE_NAME=".zshrc"
DOTFILES_RC=$(readlink -f "${HOME}/${RC_FILE_NAME}")
if [[ "${DOTFILES_RC}" != "${HOME}/${RC_FILE_NAME}" ]]
then
    export DOTFILES=$(dirname $(dirname "$DOTFILES_RC"))
    IS_DOTFILES=1
else
    export DOTFILES="$HOME"
    IS_DOTFILES=0
fi

if [[ "$IS_DOTFILES" == "1" ]]
then

    source $DOTFILES/src/zsh/autoload.zsh
fi

# Load additional custom files
# * ~/.zsh_aliases can be used for additional aliases.
# * ~/.zsh_path can be used to extend `$PATH`.
# * ~/.zsh_extra can be used for other settings you don’t want to commit.
for file in ~/.zsh_{path,prompt,exports,aliases,functions,extra}; do
	[ -e "$file" ] && source "$file";
done;
unset file;
