# mise.zsh - Mise manager implementation

pkg.define_manager "mise" \
    "name=Mise" \
    "url=https://mise.jdx.dev/"

pkg.managers.mise.is_available() {
    (( $+commands[mise] ))
}

pkg.managers.mise.enabled() {
    local rid="$1"
    pkg.managers.mise.is_available && return 0
    [[ "$rid" == "mise" ]] && return 1
    pkg.action_is_enabled "$(pkg.recipe_action "mise")"
}

pkg.managers.mise.check() {
    pkg.managers.mise.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:mise]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local installed_raw=$(mise ls --global --no-header 2>/dev/null | grep -v "(missing)")
    local -a installed=( ${(f)installed_raw} )

    local pkg base_pkg
    for pkg in "${pkgs[@]}"; do
        base_pkg="${pkg%@*}"
        # Native Zsh array search
        [[ -n ${(M)installed:#$base_pkg *} ]] || return 1
    done
    return 0
}

pkg.managers.mise.install() {
    pkg.managers.mise.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "install:mise"); do
        local p=$(pkg.recipe_packages "$rid" "mise")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    local p; for p in ${=pkgs}; do
        mise use --global "$p" || return $?
    done
}

pkg.managers.mise.update() {
    pkg.managers.mise.is_available || return 0
    mise update
}

pkg.managers.mise.upgrade() {
    pkg.managers.mise.install
}

pkg.managers.mise.cleanup() {
    pkg.managers.mise.is_available || return 0
    mise prune -y 2>/dev/null
}

pkg.managers.mise.exec() {
    pkg.managers.mise.is_available || return 1
    local rid=$1 cmd=$2; shift 2
    mise exec "$cmd" -- "$@"
}

pkg.managers.mise.search() {
    pkg.managers.mise.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:mise]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg base_pkg
    for pkg in "${pkgs[@]}"; do
        base_pkg="${pkg%@latest}"
        mise ls-remote "$base_pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}
