
# Load in the dotfiles files
for file in ${0:A:h}/config/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;
