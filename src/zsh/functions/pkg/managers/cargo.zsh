# cargo.zsh - Cargo manager implementation

pkg.managers.cargo.is_available() {
    (( $+commands[cargo] ))
}

pkg.managers.cargo.enabled() {
    pkg.managers.cargo.is_available && return 0
    pkg.action_is_enabled "$(pkg.recipe_action "cargo")"
}

pkg.managers.cargo.check() {
    pkg.managers.cargo.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:cargo]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        cargo install --list | grep -q "^$pkg " || return 1
    done
    return 0
}

pkg.managers.cargo.update() { return 0; }
pkg.managers.cargo.cleanup() { return 0; }

pkg.managers.cargo.search() {
    pkg.managers.cargo.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:cargo]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        cargo search --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg = " || return 1
    done
    return 0
}

pkg.managers.cargo.install() {
    pkg.managers.cargo.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "install:cargo"); do
        local p=$(pkg.recipe_packages "$rid" "cargo")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    cargo install ${=pkgs}
}

pkg.managers.cargo.upgrade() {
    pkg.managers.cargo.install
}
