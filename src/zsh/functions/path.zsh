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
    #escape the string first
    dir=$(echo "$@" | sed -e 's/[\/&]/\\&/g')
    #remove the path
    export PATH=$(echo $PATH | sed "s/^${dir}://g" | sed "s/:${dir}$//g" | sed "s/:${dir}:/:/g")
}

_paths_paths() {
    echo -e ${PATH//:/\\n}
}

