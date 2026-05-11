# KeePassXC shell integration
# Thin interactive wrapper around df.secrets.kp binary.

export KEEPASS_DB_PATH="${KEEPASS_DB_PATH:-$HOME/.keepass/Accounts.kdbx}"

##
# Main wrapper function for keepassxc-cli
#
# Delegates to df.secrets.kp for all vault operations.
# Special cases: "forget" and "help" are handled directly.
#
# @param string $1 Command (show, ls, search, etc.) or empty for help
# @param mixed ... Additional arguments passed to keepassxc-cli
# @return 0 on success, 1 on error
##
kp() {
    [[ "$1" == "forget" ]] && { df.secrets.kp forget; return 0 }
    [[ -z "$1" || "$1" == "help" ]] && { df.secrets.kp --help; return 0 }

    # Map interactive commands to binary subcommands.
    # We avoid a generic 'exec' for security reasons.
    case "$1" in
        show|ls|find|find-first|find-title|audit|audit-tag|audit-entry|login|db-path|cli)
            df.secrets.kp "$@"
            ;;
        search)
            # Compatibility alias for find
            df.secrets.kp find "${@:2}"
            ;;
        *)
            echo "kp: Command '$1' is not supported via this wrapper for security reasons." >&2
            echo "Use df.secrets.kp --help to see available commands." >&2
            return 1
            ;;
    esac
}

##
# Clear cached credentials from keychain
##
kp.forget() {
    df.secrets.kp forget
}

##
# Verify access to the database (login/prompt flow)
#
# @return 0 on success, 1 on failure
##
kp.login() {
    df.secrets.kp login
}

##
# Find KeePass entries (exact tail-matched title paths)
#
# @param string $1 Search title
# @return 0 on success, 1 on error/no results
##
kp.find() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: kp.find <title>" >&2
        return 1
    fi

    local results
    results=$(df.secrets.kp find "$1" 2>/dev/null \
        | awk -F/ -v search="$1" 'tolower($NF) == tolower(search)')

    if [[ -z "$results" ]]; then
        echo "No exact matches found for title '$1'" >&2
        return 1
    fi

    echo "$results"
}

##
# Find the first KeePass entry with an exact tail (title) match
#
# @param string $1 Search title
# @return 0 on success, 1 on error/no results
##
kp.find.title() {
    df.secrets.kp find-title "$1"
}

##
# Find the first KeePass entry matching a query (no title matching)
#
# @param string $1 Search query
# @return 0 on success, 1 on error/no results
##
kp.find.first() {
    df.secrets.kp find-first "$1"
}

##
# Tab completion for kp function (Oh My Zsh required)
# Only register when interactive and Oh My Zsh is loaded
if [[ -o interactive ]] && (( $+functions[compdef] )); then
    _kp_completion() {
        local -a commands=(
            'show:Show an entry'
            'ls:List entries'
            'find:Find entry paths'
            'find-first:First matching path'
            'find-title:First matching path (exact title)'
            'login:Verify/prompt for master password'
            'forget:Clear password from keychain'
            'db-path:Print database path'
        )
        _describe 'keepass command' commands
    }
    compdef _kp_completion kp
fi
