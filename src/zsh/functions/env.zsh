# env.zsh - Lazy-loaded environment variables

typeset -gA _ENV_LAZY_DEPS _ENV_LAZY_VARS

env.print.kv() {
  printf '%s=%q\n' "$1" "${*[2,-1]}"
}

env.print.var() {
  env.lazy.load "$@"
  local var; for var in "$@"; do
    env.print.kv "$var" "${(P)var}"
  done
}

env.lazy.register() {
  local var=$1 cmd=$2; shift 2
  [[ $var != [a-zA-Z_][a-zA-Z0-9_]* ]] && { print -u2 "env.lazy.register: invalid name: $var"; return 1; }
  _ENV_LAZY_VARS[$var]=$cmd
  [[ $# -gt 0 ]] && _ENV_LAZY_DEPS[$var]="$*"
}

env.lazy.load() {
  local -A seen
  local var dep deps exit_code value
  for var in "$@"; do
    [[ -v $var || -z ${_ENV_LAZY_VARS[$var]} ]] && continue
    
    deps=( ${=_ENV_LAZY_DEPS[$var]} )
    for dep in $deps; do
      if [[ -z ${seen[$dep]} ]]; then
        eval "$dep" >/dev/null
        seen[$dep]=1
      fi
    done

    value=$(eval "${_ENV_LAZY_VARS[$var]}") exit_code=$?
    if (( exit_code == 0 )); then
      export "$var=$value"
    else
      print -u2 "env.lazy.load: failed to load $var"
    fi
  done
}

env.lazy.reset() {
  local var; for var in "$@"; do
    [[ -n ${_ENV_LAZY_VARS[$var]} && -v $var ]] && unset "$var"
  done
}

env.lazy.load_all() {
  env.lazy.load ${(k)_ENV_LAZY_VARS}
}

env.print.kv_all() {
  local var; for var in ${(k)_ENV_LAZY_VARS}; do
    env.print.var "$var"
  done
}

env.get() {
  env.lazy.load "$1"
  echo "${(P)1}"
}

env.source.file() {
  local env_file=$1 key value line
  [[ -f "$env_file" ]] || return 1
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  local -a lines=( ${(f)"$(<"$env_file")"} )
  for line in "${lines[@]}"; do
    [[ "$line" == [[:space:]]*# || -z "${line//[[:space:]]/}" ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    # Trim spaces
    key="${${key##[[:space:]]##}%%[[:space:]]##}"
    value="${${value##[[:space:]]##}%%[[:space:]]##}"
    # Remove quotes
    [[ "$value" == (\'*\'|\"*\" ) ]] && value="${${value#?}%?}"
    [[ "$key" == [a-zA-Z_][a-zA-Z0-9_]* ]] && export "$key=$value"
  done
}
