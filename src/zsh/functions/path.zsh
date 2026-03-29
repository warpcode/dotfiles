#!/usr/bin/env zsh
# =============================================================================
# SYNOPSIS
#   Manage PATH environment variable via Zsh native array-tied 'path'
# =============================================================================

# Ensure path is unique and global. Zsh automatically ties 'path' to 'PATH'.
typeset -gU path

##
# Append a directory to PATH if it does not already exist.
#
# @param 1 The directory to append
# @return 0 on success, 1 if directory does not exist
##
paths.append() {
    local d="${1%/}"
    [[ -d "$d" ]] || return 1
    # If already in path, do nothing
    (( ${path[(I)$d]} )) && return 0
    path+=("$d")
}

##
# Prepend a directory to PATH if it does not already exist.
#
# @param 1 The directory to prepend
# @return 0 on success, 1 if directory does not exist
##
paths.prepend() {
    local d="${1%/}"
    [[ -d "$d" ]] || return 1
    # If already in path, do nothing
    (( ${path[(I)$d]} )) && return 0
    path=("$d" $path)
}

##
# Remove a directory from PATH.
#
# @param 1 The directory to remove
# @return 0 always
##
paths.remove() {
    local d="${1%/}"
    path=(${path:#$d})
}

##
# Display each directory in PATH on a new line.
#
# @stdout PATH directories, one per line
# @return 0 always
##
paths.ls() {
    print -l $path
}

##
# Reload PATH configuration and rehash the command hash table.
#
# @return 0 always
##
paths.reload() {
    local config="${DOTFILES:-$HOME/src/dotfiles}/src/zsh/config/01-paths.zsh"
    [[ -f "$config" ]] && source "$config"
    rehash
}
