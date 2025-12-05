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

    local password
    password=$(kp.login) || return 1

    echo "$password" | eval "$cli_cmd" "$cmd" "$KEEPASS_DB_PATH" "$@" -q
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
# Prompts user for password and validates it
#
# @return password on success, empty on failure
##
kp.login() {
    local cli_cmd
    if ! cli_cmd=$(kp.cli); then
        echo "Error: keepassxc-cli not found" >&2
        return 1
    fi

    echo -n "Enter KeePassXC password: " >&2
    read -s password
    echo >&2

    if echo "$password" | eval "$cli_cmd" db-info "$KEEPASS_DB_PATH" >/dev/null 2>&1; then
        echo "$password"
        return 0
    else
        echo "Invalid password" >&2
        return 1
    fi
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
