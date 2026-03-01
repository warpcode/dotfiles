#!/usr/bin/env zsh
# =============================================================================
#
# SYNOPSIS
#   Manage PATH environment variable
#
# DESCRIPTION
#   A collection of functions for manipulating and displaying the PATH
#   environment variable. These functions handle directory existence checks,
#   prevent duplicates, and provide convenient access to path operations.
#
# =============================================================================

##
# Append a directory to PATH if it does not already exist.
#
# @param 1 The directory to append
# @return 0 on success, 1 if directory does not exist
##
paths.append(){
    [ ! -d "$1" ] && return 1

    paths.remove "$1"
    export PATH="$PATH:$1"
}

##
# Prepend a directory to PATH if it does not already exist.
#
# @param 1 The directory to prepend
# @return 0 on success, 1 if directory does not exist
##
paths.prepend(){
    [ ! -d "$1" ] && return 1

    paths.remove "$1"
    export PATH="$1:$PATH"
}

##
# Remove a directory from PATH.
#
# @param 1 The directory to remove
# @return 0 always
##
paths.remove(){
    local -a path_array
    path_array=(${(s.:.)PATH})
    path_array=(${path_array:#$1})
    export PATH=${(j.:.)path_array}
}

##
# Display each directory in PATH on a new line.
#
# @stdout PATH directories, one per line
# @return 0 always
##
paths.paths() {
    echo -e ${PATH//:/\\n}
}

##
# Reload PATH configuration and rehash the command hash table.
#
# Sources the paths configuration file and rebuilds the command hash table
# to pick up any new commands added to PATH directories.
#
# @return 0 always
##
paths.reload() {
    local paths_config="${DOTFILES}/src/zsh/config/01-paths.zsh"
    [[ -f "$paths_config" ]] && source "$paths_config"
    rehash
}
