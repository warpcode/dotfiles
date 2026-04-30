# Generic Caching Utility - Secured
# Thin wrappers around bin/df.cache.
# Usage: cache.get <namespace> <key> [ttl_seconds]
#        cache.set <namespace> <key> <value>

typeset -g CACHE_BASE_DIR="$HOME/.cache/dotfiles"

# Check if a cache entry is stored encrypted
cache.is_encrypted() {
    df.cache is-encrypted "$@"
}

cache.get() {
    df.cache get "$@"
}

cache.set() {
    df.cache set "$@"
}

cache.del() {
    df.cache del "$@"
}

cache.clear() {
    df.cache clear "$@"
}
