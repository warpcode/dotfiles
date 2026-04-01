# npm.zsh - NPM manager implementation

pkg.managers.npm.is_available() {
    (( $+commands[npm] ))
}

pkg.managers.npm.enabled() {
    pkg.managers.npm.is_available && return 0
    pkg.action_is_enabled "$(pkg.recipe_action "node")"
}

pkg.managers.npm.check() {
    pkg.managers.npm.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:npm]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg base_pkg
    for pkg in "${pkgs[@]}"; do
        base_pkg="${pkg%@*}"
        npm list -g "$base_pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.npm.update() { return 0; }

pkg.managers.npm.cleanup() {
    pkg.managers.npm.is_available || return 0
    npm cache clean --force
}

pkg.managers.npm.exec() {
    pkg.managers.npm.is_available || return 1
    local rid=$1 cmd=$2; shift 2
    npm exec "$cmd" -- "$@"
}

pkg.managers.npm.search() {
    pkg.managers.npm.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:npm]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        npm view "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.npm.install() {
    pkg.managers.npm.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "install:npm"); do
        local p=$(pkg.recipe_packages "$rid" "npm")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    npm install -g ${=pkgs}
}

pkg.managers.npm.upgrade() {
    pkg.managers.npm.install
}
