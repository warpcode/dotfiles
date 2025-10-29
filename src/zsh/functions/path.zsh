# Append a directory to PATH if it exists
# @param dir The directory to append
_paths_append(){
    [ ! -d "$@" ] && return

    _paths_remove "$@"
    export PATH="$PATH:$@"
}

# Prepend a directory to PATH if it exists
# @param dir The directory to prepend
_paths_prepend(){
    [ ! -d "$@" ] && return

    _paths_remove "$@"
    export PATH="$@:$PATH"
}

# Remove a directory from PATH
# @param dir The directory to remove
_paths_remove(){
    local -a path_array
    path_array=(${(s.:.)PATH})
    path_array=(${path_array:#$@})
    export PATH=${(j.:.)path_array}
}

# Display PATH with each directory on a new line
# @return 0
_paths_paths() {
    echo -e ${PATH//:/\\n}
}

