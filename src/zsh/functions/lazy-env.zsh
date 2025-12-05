typeset -gA _LAZY_VARS
typeset -gA _LAZY_LOADED

_lazy_env() {
  _LAZY_VARS[$1]=$2
  _LAZY_LOADED[$1]=0
}

# Load a specific variable
_load_lazy() {
  local var=$1
  if [[ $_LAZY_LOADED[$var] -eq 0 ]]; then
    export "$var"="$(eval ${_LAZY_VARS[$var]})"
    _LAZY_LOADED[$var]=1
  fi
}

# Hook that loads vars before command execution
_check_lazy_vars() {
  local cmd=$1
  for var in ${(k)_LAZY_VARS}; do
    # Check if variable is referenced
    if [[ $cmd =~ (^|[^A-Z_])$var([^A-Z_]|$) ]] && [[ $_LAZY_LOADED[$var] -eq 0 ]]; then
      _load_lazy $var
    fi
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _check_lazy_vars
