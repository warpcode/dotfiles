# Append to $PATH
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

path_prepend "/usr/local/bin"
path_prepend "/usr/local/sbin"
path_prepend "${HOME}/.local/bin"
path_prepend "${HOME}/bin"

# Dotfiles bin files should be the least priority
path_append "${DOTFILES}/bin"
path_append "${DOTFILES}/node_modules/.bin"
path_append "${DOTFILES}/php_modules/bin"
