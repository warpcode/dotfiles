# Global variable to cache KeePassXC password for the session
typeset -g KP_PASSWORD

##
# Main wrapper function for keepassxc-cli
#
# Provides a convenient interface to keepassxc-cli
#
# @param string $1 Command (show, ls, search, etc.) or empty for help
# @param mixed ... Additional arguments passed to keepassxc-cli
# @return 0 on success, 1 on error
##
kp() {
    local cmd
    if [[ $# -gt 0 ]]; then
        cmd="$1"
        shift
    else
        cmd=""
    fi

    local cli_cmd
    if ! cli_cmd=$(kp.cli); then
        echo "Error: keepassxc-cli not found. Please install KeePassXC." >&2
        return 1
    fi

    if [[ -z "$cmd" ]] || [[ "$cmd" == "help" ]]; then
        eval "$cli_cmd" --help
        return 0
    fi

    if ! kp.login; then
        return 1
    fi

    local -a cmd_array
    if [[ $cli_cmd == *" "* ]]; then
        cmd_array=(${(z)cli_cmd})
    else
        cmd_array=("$cli_cmd")
    fi
    local cmd_str="${cmd_array[1]}"
    for arg in "${cmd_array[@]:1}" "$cmd" "$KEEPASS_DB_PATH" "$@" "-q"; do
        cmd_str+=" "$(printf '%q' "$arg")
    done
    echo "$KP_PASSWORD" | eval "$cmd_str"
}

##
# Detect keepassxc-cli installation and return the command
#
# Checks for keepassxc-cli in PATH, flatpak, or snap installations
#
# @return string The CLI command to use, or empty string if not found
##
kp.cli() {
    if (( $+commands[keepassxc-cli] )); then
        echo "keepassxc-cli"
        return 0
    fi

    if (( $+commands[flatpak] )); then
        if flatpak list 2>/dev/null | grep -q "org.keepassxc.KeePassXC"; then
            echo "flatpak run --command=keepassxc-cli org.keepassxc.KeePassXC"
            return 0
        fi
    fi

    if (( $+commands[snap] )); then
        if snap list 2>/dev/null | grep -q "keepassxc"; then
            echo "snap run keepassxc.cli"
            return 0
        fi
    fi

    return 1
}

##
# Get/prompt for password
#
# Prompts user for password and validates it, caching for the session
#
# @return 0 on success, 1 on failure
##
kp.login() {
    # Return if password is already cached
    if [[ -n "$KP_PASSWORD" ]]; then
        return 0
    fi

    local cli_cmd
    if ! cli_cmd=$(kp.cli); then
        echo "Error: keepassxc-cli not found" >&2
        return 1
    fi

    echo -n "Enter KeePassXC password: " >&2
    read -s password
    echo >&2

    if echo "$password" | eval "$cli_cmd" db-info "$KEEPASS_DB_PATH" >/dev/null 2>&1; then
        # Cache the password for the session
        KP_PASSWORD="$password"
        return 0
    else
        echo "Invalid password" >&2
        return 1
    fi
}

##
# Search for KeePass entries and return paths
#
# @param string $1 Search query
# @return 0 on success, 1 on error/no results
##
kp.search() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: kp.search <query>" >&2
        return 1
    fi

    if ! kp.login; then
        return $?
    fi

    local output
    local exit_code
    
    output=$(kp search -p "$1")
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        return $exit_code
    fi

    if [[ -z "$output" ]]; then
        echo "No entries found for '$1'" >&2
        return 1
    fi

    echo "$output"
}

##
# Search for KeePass entries and return the first path found
#
# @param string $1 Search query
# @return 0 on success, 1 on error/no results
##
kp.search.first() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: kp.search.first <query>" >&2
        return 1
    fi

    local output
    local exit_code
    
    output=$(kp.search "$1")
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        return $exit_code
    fi

    echo "$output" | head -n 1
}

##
# Tab completion for kp function
#
# Provides tab completion for keepassxc-cli commands
#
# @param array $words Array of command line words
# @param int $cword Index of current word
# @param array $line Array of command line
##
_kp_completion() {
    local -a commands=(
        'show:Show an entry'
        'ls:List entries'
        'search:Search entries'
        'clip:Copy password to clipboard'
        'add:Add new entry'
        'edit:Edit entry'
        'rm:Remove entry'
    )
    _describe 'keepass command' commands
}

compdef _kp_completion kp
