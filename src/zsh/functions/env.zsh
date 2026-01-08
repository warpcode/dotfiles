typeset -gA _ENV_LAZY_DEPS
typeset -gA _ENV_LAZY_VARS
typeset -gA _ENV_LAZY_LOADED
typeset -gA _ENV_LAZY_LOAD_ATTEMPTS

##
# Prints a key-value pair with quoted value.
# @param key The key name
# @param ... The value (all remaining args)
##
env.print.kv() {
    local key=$1; shift
    local val="$*"
    # printf %q escapes for shell-safe representation; to write raw literal, use proper quoting
    printf '%s=%q\n' "$key" "$val"
}

##
# Prints the values of environment variables.
# @param ... Variable names to print
##
env.print.var() {
    env.load "$@"
    for var in "$@"; do
        env.print.kv "$var" "${(P)var}"
    done
}

##
# Registers a lazy-loaded environment variable.
# @param var Variable name
# @param cmd Command to evaluate for the value
##
env.register() {
    local var_name=$1
    local cmd=$2
    shift 2

    _ENV_LAZY_VARS[$var_name]=$cmd
    _ENV_LAZY_LOADED[$var_name]=0
    _ENV_LAZY_LOAD_ATTEMPTS[$var_name]=0

    # Store dependencies as space-separated list
    if [[ $# -gt 0 ]]; then
        _ENV_LAZY_DEPS[$var_name]="${*}"
    fi
}

##
# Loads one or more lazy environment variables if not already loaded.
# @param ... Variable names to load
##
env.load() {
     # Collect unique dependencies
    local -A deps_to_run
    for var in "$@"; do
        local deps="${_ENV_LAZY_DEPS[$var]}"
        if [[ -n "$deps" ]]; then
            for dep in ${=deps}; do
                deps_to_run[$dep]=1
            done
        fi
    done

    # Run dependencies
    for dep in "${(@k)deps_to_run}"; do
        eval "$dep" >/dev/null
    done

    for var in "$@"; do
        if [[ $_ENV_LAZY_LOADED[$var] -eq 0 ]]; then
            # Skip lazy loading if variable is already set (respect existing values)
            if [[ -n ${(P)var} ]]; then
                _ENV_LAZY_LOADED[$var]=1
                continue
            fi

            local cmd="${_ENV_LAZY_VARS[$var]}"
            local value="$(eval $cmd)"
            local exit_code=$?

            # Only mark as loaded if command succeeded (exit code 0)
            if [[ $exit_code -eq 0 ]]; then
                export "$var"="$value"
                _ENV_LAZY_LOADED[$var]=1
                _ENV_LAZY_LOAD_ATTEMPTS[$var]=0
            else
                # Increment failure counter and mark as loaded after max retries (default: 3)
                local max_retries=${_ENV_LAZY_MAX_RETRIES:-3}
                _ENV_LAZY_LOAD_ATTEMPTS[$var]=$((_ENV_LAZY_LOAD_ATTEMPTS[$var] + 1))

                if [[ $_ENV_LAZY_LOAD_ATTEMPTS[$var] -ge $max_retries ]]; then
                    export "$var"=""
                    _ENV_LAZY_LOADED[$var]=1
                fi
            fi
        fi
    done
}

##
# Gets the value of a lazy-loaded environment variable.
# Loads the variable if needed and prints its value.
# @param var Variable name to get
##
env.get() {
    local var=$1
    env.load "$var"
    echo "${(P)var}"
}
