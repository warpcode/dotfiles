# KeePassXC database path
export KEEPASS_DB_PATH="${KEEPASS_DB_PATH:-$HOME/.keepass/Accounts.kdbx}"

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
    [[ "$1" == "forget" ]] && { kp.forget; return 0 }

    local cli_path; cli_path=$(kp.cli) || { echo "Error: keepassxc-cli not found." >&2; return 1 }
    local -a command_array=(${(z)cli_path})

    # Show help if no command or help requested
    [[ -z "$1" || "$1" == "help" ]] && { "${command_array[@]}" --help; return 0 }

    kp.login || return 1

    # Execute with password piped from keychain
    printf '%s' "$(secret.get keepassxc)" | "${command_array[@]}" "$1" "$KEEPASS_DB_PATH" "${@:2}" -q
}

##
# Verify KeePass database existence
##
kp.verify_db() {
    if [[ -z "$KEEPASS_DB_PATH" ]]; then
        echo "Error: KEEPASS_DB_PATH is not set." >&2
        return 1
    fi
    if [[ ! -f "$KEEPASS_DB_PATH" ]]; then
        echo "Error: KeePass database not found at '$KEEPASS_DB_PATH'." >&2
        return 1
    fi
}

##
# Clear cached credentials from keychain
##
kp.forget() {
    secret.delete "keepassxc"
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
# Verify access to the database
#
# Logic:
# 1. Attempt to get password from keychain via secret.get (non-interactive).
# 2. If no password found, call secret.store "keepassxc" "-" to prompt and save.
# 3. Verify the password against the DB.
# 4. If verification fails, delete from keychain.
#
# @return 0 on success, 1 on failure
##
kp.login() {
    kp.verify_db || return 1

    local cli_path; cli_path=$(kp.cli) || { echo "Error: keepassxc-cli not found." >&2; return 1 }
    local -a command_array=(${(z)cli_path})

    local password; password=$(secret.get "keepassxc")

    # If no password in keychain, prompt and store
    if [[ -z "$password" ]]; then
        secret.store "keepassxc" "-" || return 1
        password=$(secret.get "keepassxc")
    fi

    # Verify the password against the DB
    if [[ -n "$password" ]] && printf '%s' "$password" | "${command_array[@]}" db-info "$KEEPASS_DB_PATH" >/dev/null 2>&1; then
        return 0
    else
        echo "Invalid password." >&2
        kp.forget
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

    kp.login || return $?

    # Simplified search using awk for exact tail matching (case-insensitive)
    local search_results
    search_results=$(kp search "$1" | awk -F/ -v search="$1" 'tolower($NF) == tolower(search)')

    if [[ -z "$search_results" ]]; then
        echo "No exact matches found for '$1'" >&2
        return 1
    fi

    echo "$search_results"
}

##
# Search for KeePass entries and return the first path found
#
# @param string $1 Search query
# @return 0 on success, 1 on error/no results
##
kp.search.first() {
    local first_match
    first_match=$(kp.search "$1" 2>/dev/null | head -n 1)

    if [[ -z "$first_match" ]]; then
        return 1
    fi

    echo "$first_match"
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
        'forget:Clear password from keychain'
    )
    _describe 'keepass command' commands
}

compdef _kp_completion kp
