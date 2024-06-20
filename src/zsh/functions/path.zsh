path_append(){
    [ ! -d "$@" ] && return

    path_remove "$@"
    export PATH="$PATH:$@"
}

# Prepend to path
path_prepend(){
    [ ! -d "$@" ] && return

    path_remove "$@"
    export PATH="$@:$PATH"
}

# Remove from $PATH
path_remove(){
    #escape the string first
    dir=$(echo "$@" | sed -e 's/[\/&]/\\&/g')
    #remove the path
    export PATH=$(echo $PATH | sed "s/^${dir}://g" | sed "s/:${dir}$//g" | sed "s/:${dir}:/:/g")
}

paths() {
    echo -e ${PATH//:/\\n}
}
