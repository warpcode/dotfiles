typeset -gA _ENV_LAZY_DEPS
typeset -gA _ENV_LAZY_VARS

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
    env.lazy.load "$@"
    for var in "$@"; do
        env.print.kv "$var" "${(P)var}"
    done
}

##
# Registers a lazy-loaded environment variable.
# @param var Variable name
# @param cmd Command to evaluate for the value
##
env.lazy.register() {
    local var_name=$1
    local cmd=$2
    shift 2

    # Validate variable name
    if [[ ! $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        print -u2 "env.lazy.register: invalid variable name: $var_name"
        return 1
    fi

    # Validate command is non-empty
    if [[ -z $cmd ]]; then
        print -u2 "env.lazy.register: empty command for variable: $var_name"
        return 1
    fi

    _ENV_LAZY_VARS[$var_name]=$cmd

    # Store dependencies as space-separated list
    if [[ $# -gt 0 ]]; then
        _ENV_LAZY_DEPS[$var_name]="${*}"
    fi
}

##
# Loads one or more lazy environment variables if not already loaded.
# @param ... Variable names to load
##
env.lazy.load() {
     # Load dependencies and variables in a single pass
    local -A deps_seen
    for var in "$@"; do
        # Skip if variable is already set (from .env or previous load)
        if [[ -n ${(P)var} ]]; then
            continue
        fi

        # Variable is not set - run dependencies
        local deps="${_ENV_LAZY_DEPS[$var]}"
        if [[ -n "$deps" ]]; then
            for dep in ${=deps}; do
                # Only run each dependency once
                if [[ -z ${deps_seen[$dep]} ]]; then
                    eval "$dep" >/dev/null
                    deps_seen[$dep]=1
                fi
            done
        fi

        # Execute lazy load command
        local exit_code=0
        local value="$(eval "${_ENV_LAZY_VARS[$var]}")" || exit_code=$?

        # Only export if command succeeded (exit code 0)
        if [[ $exit_code -eq 0 ]]; then
            export "$var"="$value"
        else
            print -u2 "env.lazy.load: failed to load $var (exit code: $exit_code)"
        fi
    done
}

##
# Resets lazy-loaded environment variables so they can be reloaded.
# Unsets the actual environment variable (not the lazy registration).
# Only resets variables that have been registered.
# @param ... Variable names to reset
##
env.lazy.reset() {
    for var in "$@"; do
        # Only reset if the variable is registered AND set
        if [[ -n ${_ENV_LAZY_VARS[$var]} ]] && [[ -v var ]]; then
            unset -v "$var"
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
    env.lazy.load "$var"
    echo "${(P)var}"
}

##
# Sources an environment file.
# @param file Path to the .env file
##
env.source.file() {
    local env_file=$1
    [[ -f "$env_file" ]] || {
        print -u2 "env.source.file: file not found: $env_file"
        return 1
    }

    while IFS= read -r line; do
        # Skip comments (starting with #, with optional leading whitespace) and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z $line ]] && continue
        # Parse key=value (split on first =)
        if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            local key=${match[1]}
            local value=${match[2]}
            # Trim leading/trailing whitespace from key and value
            key=${key##[[:space:]]}
            key=${key%%[[:space:]]}
            value=${value##[[:space:]]}
            value=${value%%[[:space:]]}
            # Validate key: must be a valid variable name (letters, digits, underscores; start with letter/_)
            if [[ $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                printf -v "$key" %s "$value" && export "$key"
            fi
        fi
    done <"$env_file"
}
