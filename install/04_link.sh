e_header "Linking dot files"


files=(~/.dotfiles/link/*)
for file in ${files[@]}; do
    base="$(basename $file)"
    dest="$HOME/$base"
    if [[ "$file" -ef "$dest" ]]; then
        echo " - Skipping ${base} linking. Link already exists"
    else
        echo " - Linking ${base}"
        ln -sf "${$file#$HOME/}" ~/
    fi
done