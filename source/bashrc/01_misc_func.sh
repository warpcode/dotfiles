# Simple check on whether a binary is accessible via the $PATH
function _app_exists() { 
    hash "${1}" 2>/dev/null || { return 1;}
}



#########################
# Path Manipulation
#########################

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