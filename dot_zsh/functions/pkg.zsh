# pkg.zsh - Recipe Configuration & Initialization

# --- Recipe Definition ---
pkg.recipe.define() {
    local rid="${1//-/_}"; shift
    registry.define "pkg" "$rid" "$@"
}

# --- Registry Accessors ---
pkg.recipe.get() { registry.get "pkg" "$1" "$2"; }
pkg.recipe.exists() { registry.exists "pkg" "$1"; }

# --- Recipe Lifecycle Hooks ---
pkg.recipe.configure_all() {
    local id
    for id in $(registry.list pkg 2>/dev/null); do
        local rid="${id//-/_}"
        local func="pkg.recipe.${rid}.configure"
        (( $+functions[$func] )) || continue
        "$func" "$id" || tui.error "$func failed for $id"
    done
    return 0
}