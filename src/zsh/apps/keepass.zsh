# KeePassXC CLI password caching (in-memory only)

# Configuration
KEEPASS_DB_PATH="${KEEPASS_DB_PATH:-$HOME/keepass.kdbx}"
KEEPASS_CACHE_DURATION="${KEEPASS_CACHE_DURATION:-300}" # 5 minutes default

# Global variables for password caching
typeset -g _KEEPASS_PASSWORD=""
typeset -g _KEEPASS_TIMESTAMP=0

# Detect keepassxc-cli installation and return the command
_keepassxc_get_cli() {
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

# Check if cached password is still valid
_keepass_cache_valid() {
    [[ -n "$_KEEPASS_PASSWORD" && $_KEEPASS_TIMESTAMP -ne 0 ]] || return 1

    local current_time=$(date +%s)
    local age=$((current_time - _KEEPASS_TIMESTAMP))

    if [[ $age -lt $KEEPASS_CACHE_DURATION ]]; then
        return 0
    else
        _KEEPASS_PASSWORD=""
        _KEEPASS_TIMESTAMP=0
        return 1
    fi
}

# Get/prompt for password and store in global variable
_keepass_get_password() {
    _keepass_cache_valid && return 0

    local cli_cmd
    if ! cli_cmd=$(_keepassxc_get_cli); then
        echo "Error: keepassxc-cli not found" >&2
        return 1
    fi

    echo -n "Enter KeePassXC password: " >&2
    read -s password
    echo >&2

    if echo "$password" | eval "$cli_cmd" db-info "$KEEPASS_DB_PATH" >/dev/null 2>&1; then
        _KEEPASS_PASSWORD="$password"
        _KEEPASS_TIMESTAMP=$(date +%s)
        return 0
    else
        echo "Invalid password" >&2
        _KEEPASS_PASSWORD=""
        _KEEPASS_TIMESTAMP=0
        return 1
    fi
}

# Main wrapper function for keepassxc-cli
kp() {
    local cmd
    if [[ $# -gt 0 ]]; then
        cmd="$1"
        shift
    else
        cmd=""
    fi

    local cli_cmd
    if ! cli_cmd=$(_keepassxc_get_cli); then
        echo "Error: keepassxc-cli not found. Please install KeePassXC." >&2
        return 1
    fi

    if [[ -z "$cmd" ]] || [[ "$cmd" == "help" ]]; then
        eval "$cli_cmd" --help
        echo "Special: clear (clear password cache)"
        return 0
    fi

    if [[ "$cmd" == "clear" ]]; then
        _KEEPASS_PASSWORD=""
        _KEEPASS_TIMESTAMP=0
        echo "Cache cleared"
        return 0
    fi

    _keepass_get_password || return 1

    echo "$_KEEPASS_PASSWORD" | eval "$cli_cmd" "$cmd" "$KEEPASS_DB_PATH" "$@" -q
}


# Tab completion
_kp_completion() {
    local -a commands=(
        'show:Show an entry'
        'ls:List entries'
        'search:Search entries'
        'clip:Copy password to clipboard'
        'add:Add new entry'
        'edit:Edit entry'
        'rm:Remove entry'
        'clear:Clear password cache'
    )
    _describe 'keepass command' commands
}

compdef _kp_completion kp
