typeset -gA _ENV_LAZY_VARS
typeset -gA _ENV_LAZY_LOADED

##
# Prints the values of environment variables.
# @param ... Variable names to print
##
_env_print() {
    for var in "$@"; do
        echo "$var=${(P)var}"
    done
}

##
# Exports environment variables to a .env file.
# @param ... Variable names to export
##
_env_export() {
    _env_print "$@" > .env
}

##
# Registers a lazy-loaded environment variable.
# @param var Variable name
# @param cmd Command to evaluate for the value
##
_env_lazy() {
    _ENV_LAZY_VARS[$1]=$2
    _ENV_LAZY_LOADED[$1]=0
}

##
# Loads a specific lazy environment variable if not already loaded.
# @param var Variable name to load
##
_env_load_lazy() {
    local var=$1
    if [[ $_ENV_LAZY_LOADED[$var] -eq 0 ]]; then
        export "$var"="$(eval ${_ENV_LAZY_VARS[$var]})"
        _ENV_LAZY_LOADED[$var]=1
    fi
}

##
# Hook function that checks and loads lazy variables before command execution.
# @param cmd The command being executed
##
_env_check_lazy_vars() {
    local cmd=$1
    for var in ${(k)_ENV_LAZY_VARS}; do
        # Check if variable is referenced
        if [[ $cmd =~ (^|[^A-Z_])$var([^A-Z_]|$) ]] && [[ $_ENV_LAZY_LOADED[$var] -eq 0 ]]; then
            _env_load_lazy $var
        fi
    done
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _env_check_lazy_vars

