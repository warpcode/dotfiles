# KeePassXC shell integration
# Thin interactive wrapper around df.secrets.kp binary.

export KEEPASS_DB_PATH="${KEEPASS_DB_PATH:-$HOME/.keepass/Accounts.kdbx}"

##
# Main wrapper function for keepassxc-cli
#
# Delegates to df.secrets.kp for all vault operations.
# Special cases: "forget" and "help" are handled directly.
# All other commands are passed through via `df.secrets.kp exec`.
#
# @param string $1 Command (show, ls, search, etc.) or empty for help
# @param mixed ... Additional arguments passed to keepassxc-cli
# @return 0 on success, 1 on error
##
kp() {
    [[ "$1" == "forget" ]] && { df.secrets.kp forget; return 0 }
    [[ -z "$1" || "$1" == "help" ]] && { df.secrets.kp --help; return 0 }

    df.secrets.kp exec "$@"
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
# Search for KeePass entries and return exact tail-matched paths
#
# @param string $1 Search query
# @return 0 on success, 1 on error/no results
##
kp.search() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: kp.search <query>" >&2
        return 1
    fi

    local search_results
    search_results=$(df.secrets.kp search "$1" 2>/dev/null \
        | awk -F/ -v search="$1" 'tolower($NF) == tolower(search)')

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
    df.secrets.kp search-first "$1"
}

##
# Tab completion for kp function (Oh My Zsh required)
# Only register when interactive and Oh My Zsh is loaded
if [[ -o interactive ]] && (( $+functions[compdef] )); then
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
fi
