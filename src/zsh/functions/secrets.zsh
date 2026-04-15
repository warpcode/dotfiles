# secrets.zsh - Universal Secret Manager

_secrets.prefix() {
    local svc=${${1#/}#dotfiles/}   # strip leading / and dotfiles/ if present
    echo "dotfiles/${svc}"
}

_secrets_exec() {
    local op=$1 svc=$2 val=$3
    if (( $+commands[security] )); then
        case $op in
            get) security find-generic-password -a "$USER" -s "$svc" -w 2>/dev/null ;;
            del) security delete-generic-password -a "$USER" -s "$svc" &>/dev/null ;;
            set) security delete-generic-password -a "$USER" -s "$svc" &>/dev/null
                security add-generic-password -a "$USER" -s "$svc" -w "$val" -U &>/dev/null ;;
        esac
    elif (( $+commands[secret-tool] )); then
        case $op in
            get) secret-tool lookup service "$svc" account "$USER" 2>/dev/null ;;
            del) secret-tool clear service "$svc" account "$USER" &>/dev/null ;;
            set) print -nr "$val" | secret-tool store --label="Dotfiles: $svc" service "$svc" account "$USER" ;;
        esac
    else
        return 127
    fi
}

secrets.get() {
    local svc=$1
    [[ -z $svc ]] && return 1
    _secrets_exec get "$(_secrets.prefix "$svc")"
}

secrets.store() {
    local svc=$1 pass=$2
    [[ -z $svc || -z $pass ]] && return 1

    if [[ $pass == "-" ]]; then
        read -rs "pass?Enter password for '$svc' ($USER): "; echo >&2
        [[ -z $pass ]] && return 1
    fi

    _secrets_exec set "$(_secrets.prefix "$svc")" "$pass" || return 1
    tui.success "Saved to OS keychain." >&2
}

secrets.delete() {
    local svc=$1
    [[ -z $svc ]] && return 1
    _secrets_exec del "$(_secrets.prefix "$svc")" && tui.warn "Removed from OS keychain." >&2
}

# --- Smart Secret Management (Registry-backed) ---

# Register a secret with its fallback source (e.g. KeePass)
# secrets.register <var_name> <svc_name> <fallback_cmd>
secrets.register() {
    local var="$1" svc="$2" cmd="$3"
    registry.define "secrets" "$var" "svc=$svc" "cmd=$cmd"
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
    local cmd=$(registry.get "secrets" "$var" "cmd")

    [[ -z "$svc" ]] && return 1

    # 3. Tier 2: OS Keychain (Persistent Hot Cache)
    local value=$(secrets.get "$svc" 2>/dev/null)
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
        secrets.store "$svc" "$value" 2>/dev/null
        echo "$value"
        return 0
    fi
    return 1
}


# Purge registered secrets by service prefix (registered-only)
# secrets.purge <prefix>
secrets.purge() {
    local prefix=$1
    [[ -z "$prefix" ]] && return 1

    # Normalize via _secrets.prefix, then enforce trailing slash as group boundary
    prefix="$(_secrets.prefix "${prefix%/}")/"

    local ns="secrets"
    local ids
    ids=( $(registry.list "$ns") )
    local id svc full_svc
    for id in "${ids[@]}"; do
        svc=$(registry.get "$ns" "$id" "svc")
        [[ -z "$svc" ]] && continue
        full_svc="$(_secrets.prefix "$svc")"
        if [[ "$full_svc" == "$prefix"* ]]; then
            # 1) Clear Tier 1 (Runtime env var)
            unset "$id" 2>/dev/null || true
            # 2) Clear Tier 2 (OS Keychain) — acct enforced to $USER
            secrets.delete "$svc" >/dev/null 2>&1 || true
        fi
    done
}


# Force refresh a secret from cold storage and echo new value
secrets.refresh() {
    local var="$1"
    local svc=$(registry.get "secrets" "$var" "svc")

    [[ -z "$svc" ]] && return 1

    # 1. Clear Tier 1 (Runtime)
    unset "$var"

    # 2. Clear Tier 2 (OS Keychain)
    secrets.delete "$svc"

    # 3. Reload from Tier 3 (Cold Storage)
    secrets.resolve "$var"
}
