# npm.zsh - NPM manager implementation

pkg.manager.define "npm" \
    "name=NPM" \
    "url=https://www.npmjs.com/"

pkg.managers.npm.is_available() {
    (( $+commands[npm] ))
}

pkg.managers.npm.enabled() {
    pkg.managers.npm.is_available && return 0
    pkg.recipe.action_is_enabled "$(pkg.recipe.action "node")"
}

pkg.managers.npm.check() {
    pkg.managers.npm.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" npm):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg base_pkg
    for pkg in "${pkgs[@]}"; do
        if [[ "$pkg" == @* ]]; then
            # Scoped package: strip @version only if present after the slash
            [[ "$pkg" == */*@* ]] && base_pkg="${pkg%@*}" || base_pkg="$pkg"
        else
            base_pkg="${pkg%@*}"
        fi
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
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" npm):-$(pkg.recipe.get "$rid" package)} )
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
    for rid in $(pkg.recipe.by_action "install:npm"); do
        local p=$(pkg.recipe.packages "$rid" "npm")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    npm install -g ${=pkgs}
}

pkg.managers.npm.upgrade() {
    pkg.managers.npm.install
}
