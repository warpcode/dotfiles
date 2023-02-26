# Append to $PATH
function _append_to_path(){
    _remove_from_path "$@"
    export PATH="$PATH:$@"
}

# Prepend to path
function _prepend_to_path(){
    _remove_from_path "$@"
    export PATH="$@:$PATH"
}

# Remove from $PATH
function _remove_from_path(){
    #escape the string first
    dir=$(echo "$@" | sed -e 's/[\/&]/\\&/g')
    #remove the path
    export PATH=$(echo $PATH | sed "s/^${dir}://g" | sed "s/:${dir}$//g" | sed "s/:${dir}:/:/g")
}

if [[ "$OSTYPE" =~ ^darwin ]]
then
    if [[ -f "/usr/local/bin/ruby" ]]
    then
    	_prepend_to_path "/usr/local/opt/ruby/bin"
    fi

    # OSX doesn't have /usr/local/bin or /usr/local/sbin in the path
    _prepend_to_path "/usr/local/bin"
    _prepend_to_path "/usr/local/sbin"
fi

_prepend_to_path "${HOME}/.local/bin"
_prepend_to_path "${HOME}/bin"
