# Generic Caching Utility - Secured
# Usage: cache.get <namespace> <key> [ttl_seconds]
#        cache.set <namespace> <key> <value>

typeset -g CACHE_BASE_DIR="$HOME/.cache/dotfiles"
typeset -g CACHE_KEY_SERVICE="dotfiles-cache-key"
typeset -g CACHE_KEY_ACCOUNT="default"

# Ensure strict permissions on the base directory
if [[ ! -d "$CACHE_BASE_DIR" ]]; then
    mkdir -p "$CACHE_BASE_DIR"
    chmod 700 "$CACHE_BASE_DIR"
fi

# Internal: Generate a secure filename from a key
_cache.hash_key() {
    local key="${1:?}"
    # Use sha256sum to obscure the key in the filesystem
    echo -n "$key" | sha256sum | awk '{print $1}'
}

# Internal: Get or generate encryption key from OS keyring
_cache.get_key() {
    local key
    key=$(secrets.get "$CACHE_KEY_SERVICE" "$CACHE_KEY_ACCOUNT" 2>/dev/null)
    if [[ -z "$key" ]]; then
        # Generate random 32-byte key (64 hex chars)
        key=$(openssl rand -hex 32 2>/dev/null)
        if [[ -n "$key" ]]; then
            secrets.store "$CACHE_KEY_SERVICE" "$key" "$CACHE_KEY_ACCOUNT" >/dev/null 2>&1
        fi
    fi
    echo "$key"
}

# Internal: Check if encryption is available (has openssl - key can be generated if needed)
_cache.can_encrypt() {
    (( $+commands[openssl] ))
}

# Internal: Generate file paths for encrypted and plaintext cache
_cache.encrypted_file() {
    local ns="$1" hashed_key="$2"
    echo "$CACHE_BASE_DIR/$ns/$hashed_key.enc.cache"
}

_cache.plaintext_file() {
    local ns="$1" hashed_key="$2"
    echo "$CACHE_BASE_DIR/$ns/$hashed_key.cache"
}

# Internal: Encrypt a value using OpenSSL AES-256-CBC
_cache.encrypt() {
    local value="$1"
    local key="$2"
    echo -n "$value" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass "pass:$key" -base64 -A 2>/dev/null
}

# Internal: Decrypt a value using OpenSSL AES-256-CBC
_cache.decrypt() {
    local encrypted="$1"
    local key="$2"
    echo -n "$encrypted" | openssl enc -d -aes-256-cbc -pbkdf2 -pass "pass:$key" -base64 -A 2>/dev/null
}

# Check if a cache entry is stored encrypted
cache.is_encrypted() {
    local ns="${1:?}"
    local key="${2:?}"
    local hashed_key=$(_cache.hash_key "$key")
    local enc_file=$(_cache.encrypted_file "$ns" "$hashed_key")
    [[ -f "$enc_file" ]]
}

cache.get() {
    local ns="${1:?}"
    local key="${2:?}"
    local ttl="${3:-86400}"
    local hashed_key=$(_cache.hash_key "$key")
    local enc_file=$(_cache.encrypted_file "$ns" "$hashed_key")
    local plain_file=$(_cache.plaintext_file "$ns" "$hashed_key")
    local cache_file=""

    # Encrypted always takes priority
    if [[ -f "$enc_file" ]]; then
        cache_file="$enc_file"
    elif [[ -f "$plain_file" ]]; then
        cache_file="$plain_file"
    fi

    if [[ -n "$cache_file" ]]; then
        local now=$(date +%s)
        local mtime=$(date -r "$cache_file" +%s)
        if (( now - mtime < ttl )); then
            local content=$(cat "$cache_file")
            # Decrypt if reading encrypted file
            if [[ "$cache_file" == *.enc.cache ]]; then
                local enc_key=$(_cache.get_key)
                local decrypted=$(_cache.decrypt "$content" "$enc_key")
                if [[ -n "$decrypted" ]]; then
                    echo "$decrypted"
                    return 0
                fi
            else
                echo "$content"
                return 0
            fi
        fi
    fi
    return 1
}

cache.set() {
    local ns="${1:?}"
    local key="${2:?}"
    local value="${3:?}"
    local cache_dir="$CACHE_BASE_DIR/$ns"
    local hashed_key=$(_cache.hash_key "$key")
    local enc_file=$(_cache.encrypted_file "$ns" "$hashed_key")
    local plain_file=$(_cache.plaintext_file "$ns" "$hashed_key")

    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
        chmod 700 "$cache_dir"
    fi

    # Encrypt if possible
    if _cache.can_encrypt; then
        local enc_key=$(_cache.get_key)
        local encrypted=$(_cache.encrypt "$value" "$enc_key")
        if [[ -n "$encrypted" ]]; then
            echo "$encrypted" > "$enc_file"
            rm -f "$plain_file"
            chmod 600 "$enc_file"
            return 0
        fi
    fi

    # Plaintext fallback
    echo "$value" > "$plain_file"
    rm -f "$enc_file"
    chmod 600 "$plain_file"
}

cache.del() {
    local ns="${1:?}"
    local key="${2:?}"
    local hashed_key=$(_cache.hash_key "$key")
    local enc_file=$(_cache.encrypted_file "$ns" "$hashed_key")
    local plain_file=$(_cache.plaintext_file "$ns" "$hashed_key")
    rm -f "$enc_file" "$plain_file"
}

cache.clear() {
    local ns="$1"
    if [[ -n "$ns" ]]; then
        rm -rf "$CACHE_BASE_DIR/$ns"
    else
        rm -rf "$CACHE_BASE_DIR"/*
    fi
}
