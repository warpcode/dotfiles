# snap.zsh - Snap manager implementation

pkg.managers.snap.is_available() {
    (( $+commands[snap] ))
}

pkg.managers.snap.enabled() {
    pkg.managers.snap.is_available
}

pkg.managers.snap.check() {
    pkg.managers.snap.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[$rid:snap]:-${pkg_recipes[$rid:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg pkg_name
    for pkg in "${pkgs[@]}"; do
        pkg_name="${pkg%% --classic}"
        snap list "$pkg_name" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.snap.update() { return 0; }
pkg.managers.snap.cleanup() { return 0; }

pkg.managers.snap.search() {
    pkg.managers.snap.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[$rid:snap]:-${pkg_recipes[$rid:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg pkg_name
    for pkg in "${pkgs[@]}"; do
        pkg_name="${pkg%% --classic}"
        snap info "$pkg_name" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.snap.install() {
    pkg.managers.snap.is_available || return 0
    local rid pkg pkg_name
    for rid in $(pkg.recipes_by_action "install:snap"); do
        pkg=$(pkg.recipe_packages "$rid" "snap")
        [[ -z "$pkg" ]] && continue
        if [[ "$pkg" == *" --classic"* ]]; then
            pkg_name="${pkg%% --classic*}"
            sudo snap install "$pkg_name" --classic || return $?
        else
            sudo snap install "$pkg" || return $?
        fi
    done
}

pkg.managers.snap.upgrade() {
    pkg.managers.snap.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "upgrade:snap"); do
        local p=$(pkg.recipe_packages "$rid" "snap")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    sudo snap refresh ${=pkgs}
}
