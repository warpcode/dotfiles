# Attempt to find the location of dotfiles
RC_FILE_NAME=".bash_profile"
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
    # Load in the dotfiles files
    for file in $DOTFILES/src/{bash,shell}/**/*.{bash,sh}; do
        [ -e "$file" ] && source "$file";
    done;
    unset file;
fi

# Load additional custom files
# * ~/.zsh_aliases can be used for additional aliases.
# * ~/.zsh_path can be used to extend `$PATH`.
# * ~/.zsh_extra can be used for other settings you don’t want to commit.
for file in ~/.bash_{path,prompt,exports,aliases,functions,extra}; do
	[ -e "$file" ] && source "$file";
done;
unset file;

# Load 3rd Party scripts

# Magicmonty/bash-git-prompt
GIT_PROMPT_ONLY_IN_REPO=1
__GIT_PROMPT_DIR="$DOTFILES/vendor/magicmonty.bash-git-prompt"
source $__GIT_PROMPT_DIR/gitprompt.sh
