# Load in the functions first
for file in ${0:A:h}/functions/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;

# Load in the dotfiles files
for file in ${0:A:h}/config/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;
