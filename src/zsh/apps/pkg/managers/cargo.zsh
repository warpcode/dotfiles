# cargo.zsh - Cargo manager implementation

pkg.manager.define "cargo" \
    "name=Cargo" \
    "url=https://doc.rust-lang.org/cargo/"

pkg.managers.cargo.is_available() {
    (( $+commands[cargo] ))
}

pkg.managers.cargo.enabled() {
    pkg.managers.cargo.is_available && return 0
    pkg.recipe.action_is_enabled "$(pkg.recipe.action "cargo")"
}

pkg.managers.cargo.check() {
    pkg.managers.cargo.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" cargo):-$(pkg.recipe.get "$rid" package)} )
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
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" cargo):-$(pkg.recipe.get "$rid" package)} )
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
    for rid in $(pkg.recipe.by_action "install:cargo"); do
        local p=$(pkg.recipe.packages "$rid" "cargo")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    cargo install ${=pkgs}
}

pkg.managers.cargo.upgrade() {
    pkg.managers.cargo.install
}
