##
# Universal Secret Manager
# Abstract wrapper for OS-level keychains (macOS Keychain, Linux Secret Service)
##

# Get a secret from the OS keychain
secret.get() {
    local service=$1 account=${2:-$USER}
    [[ -z "$service" ]] && { echo "Usage: secret.get <service> [account]" >&2; return 1 }

    if (( $+commands[security] )); then
        security find-generic-password -a "$account" -s "$service" -w 2>/dev/null
    elif (( $+commands[secret-tool] )); then
        secret-tool lookup service "$service" account "$account" 2>/dev/null
    fi
}

# Store a secret in the OS keychain (use "-" for interactive prompt)
secret.store() {
    local service=$1 password=$2 account=${3:-$USER}
    [[ -z "$service" || -z "$password" ]] && { echo "Usage: secret.store <service> <password> [account]" >&2; return 1 }

    if [[ "$password" == "-" ]]; then
        echo -n "Enter password for '$service' ($account): " >&2
        read -rs password; echo >&2
        [[ -z "$password" ]] && return 1
    fi

    if (( $+commands[security] )); then
        security delete-generic-password -a "$account" -s "$service" >/dev/null 2>&1
        security add-generic-password -a "$account" -s "$service" -w "$password" -U >/dev/null && echo "Saved to macOS Keychain." >&2
    elif (( $+commands[secret-tool] )); then
        printf '%s' "$password" | secret-tool store --label="Dotfiles: $service" service "$service" account "$account" && echo "Saved to Secret Service." >&2
    else
        echo "Error: No OS keychain tool found." >&2; return 1
    fi
}

# Remove a secret from the OS keychain
secret.delete() {
    local service=$1 account=${2:-$USER}
    [[ -z "$service" ]] && { echo "Usage: secret.delete <service> [account]" >&2; return 1 }

    if (( $+commands[security] )); then
        security delete-generic-password -a "$account" -s "$service" >/dev/null 2>&1 && echo "Removed from macOS Keychain." >&2
    elif (( $+commands[secret-tool] )); then
        secret-tool clear service "$service" account "$account" >/dev/null 2>&1 && echo "Removed from Secret Service." >&2
    fi
}
