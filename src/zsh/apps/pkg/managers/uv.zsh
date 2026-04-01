# uv.zsh - UV manager implementation

pkg.define_manager "uv" \
    "name=UV" \
    "url=https://github.com/astral-sh/uv"

pkg.managers.uv.is_available() {
    (( $+commands[uv] ))
}

pkg.managers.uv.enabled() {
    pkg.managers.uv.is_available && return 0
    pkg.action_is_enabled "$(pkg.recipe_action "uv")"
}

pkg.managers.uv.check() {
    pkg.managers.uv.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:uv]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local installed_raw=$(uv tool list 2>/dev/null)
    local -a installed=( ${(f)installed_raw} )

    local pkg
    for pkg in "${pkgs[@]}"; do
        [[ -n ${(M)installed:#$pkg *} ]] || return 1
    done
    return 0
}

pkg.managers.uv.update() { return 0; }

pkg.managers.uv.cleanup() {
    pkg.managers.uv.is_available || return 0
    uv cache clean --force 2>/dev/null
}

pkg.managers.uv.search() {
    pkg.managers.uv.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:uv]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        uv pip index versions "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.uv.install() {
    pkg.managers.uv.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "install:uv"); do
        local p=$(pkg.recipe_packages "$rid" "uv")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    uv tool install ${=pkgs}
}

pkg.managers.uv.upgrade() {
    pkg.managers.uv.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "upgrade:uv"); do
        local p=$(pkg.recipe_packages "$rid" "uv")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    uv tool upgrade ${=pkgs}
}
