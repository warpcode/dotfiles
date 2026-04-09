# secrets.zsh - Universal Secret Manager

_secrets.prefix() {
    local svc="$1"
    [[ "$svc" == dotfiles/* ]] && echo "$svc" || echo "dotfiles/${svc}"
}

_secrets_exec() {
    local op=$1 svc=$2 acct=$3 val=$4
    if (( $+commands[security] )); then
        case $op in
            get) security find-generic-password -a "$acct" -s "$svc" -w 2>/dev/null ;;
            del) security delete-generic-password -a "$acct" -s "$svc" &>/dev/null ;;
            set) security delete-generic-password -a "$acct" -s "$svc" &>/dev/null
                security add-generic-password -a "$acct" -s "$svc" -w "$val" -U &>/dev/null ;;
        esac
    elif (( $+commands[secret-tool] )); then
        case $op in
            get) secret-tool lookup service "$svc" account "$acct" 2>/dev/null ;;
            del) secret-tool clear service "$svc" account "$acct" &>/dev/null ;;
            set) print -nr "$val" | secret-tool store --label="Dotfiles: $svc" service "$svc" account "$acct" ;;
        esac
    else
        return 127
    fi
}

secrets.get() {
    local svc=$1 acct=${2:-$USER}
    [[ -z $svc ]] && return 1
    _secrets_exec get "$(_secrets.prefix "$svc")" "$acct"
}

secrets.store() {
    local svc=$1 pass=$2 acct=${3:-$USER}
    [[ -z $svc || -z $pass ]] && return 1

    if [[ $pass == "-" ]]; then
        read -rs "pass?Enter password for '$svc' ($acct): "; echo >&2
        [[ -z $pass ]] && return 1
    fi

    _secrets_exec set "$(_secrets.prefix "$svc")" "$acct" "$pass" || return 1
    print -P "    %F{green}✅ Saved to OS keychain.%f" >&2
}

secrets.delete() {
    local svc=$1 acct=${2:-$USER}
    [[ -z $svc ]] && return 1
    _secrets_exec del "$(_secrets.prefix "$svc")" "$acct" && print -P "    %F{yellow}🗑️ Removed from OS keychain.%f" >&2
}

# --- Smart Secret Management (Registry-backed) ---

# Bootstrap secrets registry namespace (idempotent)
typeset -gA registry_secrets_data registry_secrets_exists
typeset -ga registry_secrets_list

# Register a secret with its fallback source (e.g. KeePass)
# secrets.register <var_name> <svc_name> <acct_name> <fallback_cmd>
secrets.register() {
    local var="$1" svc="$2" acct="$3" cmd="$4"
    registry.define "secrets" "$var" "svc=$svc" "acct=$acct" "cmd=$cmd"
}

# Resolve a secret (Tier 1 < Tier 2 < Tier 3) and echo the value
secrets.resolve() {
    local var="$1"
    # 1. Tier 1: Env Var (Runtime Cache)
    if [[ -v "$var" ]]; then
        echo "${(P)var}"
        return 0
    fi

    # 2. Get Metadata from Registry
    local svc=$(registry.get "secrets" "$var" "svc")
    local acct=$(registry.get "secrets" "$var" "acct")
    local cmd=$(registry.get "secrets" "$var" "cmd")

    [[ -z "$svc" ]] && return 1

    # 3. Tier 2: OS Keychain (Persistent Hot Cache)
    local value=$(secrets.get "$svc" "$acct" 2>/dev/null)
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi
    # 4. Tier 3: Cold Storage (Fallback Command)
    # Run the command and capture value
    # NOTE: stderr NOT suppressed — KeePass may prompt for master password here
    value=$(eval "$cmd")
    if (( $? == 0 )) && [[ -n "$value" ]]; then
        # Promote to Tier 2: Store in OS Keychain
        secrets.store "$svc" "$value" "$acct" 2>/dev/null
        echo "$value"
        return 0
    fi
    return 1
}


# Force refresh a secret from cold storage and echo new value
secrets.refresh() {
    local var="$1"
    local svc=$(registry.get "secrets" "$var" "svc")
    local acct=$(registry.get "secrets" "$var" "acct")

    [[ -z "$svc" ]] && return 1

    # 1. Clear Tier 1 (Runtime)
    unset "$var"

    # 2. Clear Tier 2 (OS Keychain)
    secrets.delete "$svc" "$acct"

    # 3. Reload from Tier 3 (Cold Storage)
    secrets.resolve "$var"
}
