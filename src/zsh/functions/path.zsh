#!/usr/bin/env zsh
# path.zsh - Manage PATH via Zsh native array-tied 'path'

# Ensure path is unique and global. Zsh automatically ties 'path' to 'PATH'.
typeset -gU path

# Append a directory to PATH
path.append() {
    local d="${1%/}"
    [[ -d "$d" ]] || return 1
    # Zsh-native index lookup
    (( ${path[(I)$d]} )) || path+=("$d")
}

# Prepend a directory to PATH
path.prepend() {
    local d="${1%/}"
    [[ -d "$d" ]] || return 1
    (( ${path[(I)$d]} )) || path=("$d" $path)
}

# Remove a directory from PATH
path.remove() {
    path=( ${path:#${1%/}} )
}

# Display PATH directories
path.ls() {
    print -l $path
}

# Reload PATH configuration
path.reload() {
    local cfg="${DOTFILES:-$HOME/src/dotfiles}/src/zsh/config/01-paths.zsh"
    [[ -f "$cfg" ]] && source "$cfg"
    rehash
}
