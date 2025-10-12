_paths_append(){
    [ ! -d "$@" ] && return

    _paths_remove "$@"
    export PATH="$PATH:$@"
}

# Prepend to path
_paths_prepend(){
    [ ! -d "$@" ] && return

    _paths_remove "$@"
    export PATH="$@:$PATH"
}

# Remove from $PATH
_paths_remove(){
    local -a path_array
    path_array=(${(s.:.)PATH})
    path_array=(${path_array:#$@})
    export PATH=${(j.:.)path_array}
}

_paths_paths() {
    echo -e ${PATH//:/\\n}
}

