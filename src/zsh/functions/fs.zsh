
# Resolve a path within the dotfiles repository
# @param path Path relative to DOTFILES root (e.g., "configs/myapp" or "src/zsh/init.zsh")
# @return 0 if found (echoes full realpath), 1 if not found
fs.dotfiles.path() {
    local path="$1"

    if [[ -z "$path" ]]; then
        return 1
    fi

    if [[ -n "$DOTFILES" && -e "$DOTFILES/$path" ]]; then
        local full_path="$DOTFILES/$path"
        echo "${full_path:a:P}"
        return 0
    fi

    return 1
}

# Find the first parent directory containing any of the specified files/directories
# Searches upward from the current directory to the root
# @param files Array of file/directory names to search for
# @return 0 if found (echoes path), 1 if not found
fs.find.root() {
    local files=("$@")
    local dir="$PWD"

    for file in "${files[@]}"; do
        if [[ -e "$dir/$file" ]]; then
            echo "$dir/$file"
            return 0
        fi
    done

    while [[ "$dir" != "/" ]]; do
        for file in "${files[@]}"; do
            if [[ -e "$dir/$file" ]]; then
                echo "$dir/$file"
                return 0
            fi
        done
        dir=$(dirname "$dir")
    done

    return 1
}

