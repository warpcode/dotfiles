# Simple check on whether a binary is accessible via the $PATH
function _app_exists() {
    hash "${1}" 2>/dev/null || { return 1;}
}

# Grab the first that exists
# EDITOR=`first_of "mate -w" "nano -w" vi`
function _app_first_exists() {
  if [ -n "$1" ]; then
    local arg=$1
    shift
    _app_exists $arg >> /dev/null && echo $arg || _app_first_exists "$@"
  else
    exit 1
  fi
}
