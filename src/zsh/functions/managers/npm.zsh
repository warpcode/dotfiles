# src/zsh/functions/managers/npm.zsh

pkg.managers.npm.is_available() {
    command -v npm >/dev/null 2>&1
}

pkg.managers.npm.enabled() {
    pkg.managers.npm.is_available && return 0
    pkg.actionIsEnabled "$(pkg.recipeAction "$(pkg.managers.npm.recipe)")"
}

pkg.managers.npm.recipe() {
    echo "node"
}

pkg.managers.npm.check() {
    pkg.managers.npm.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.npm._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        local base_pkg="$pkg"
        [[ "$base_pkg" == ?*@* ]] && base_pkg="${base_pkg%@*}"
        npm list -g "$base_pkg" >/dev/null 2>&1 || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.npm.update() {
    return 0
}

pkg.managers.npm.cleanup() {
    pkg.managers.npm.is_available || return 0
    npm cache clean --force
}

pkg.managers.npm.exec() {
    pkg.managers.npm.is_available || return 1
    local rid=$1; shift
    local cmd=$1; shift
    npm exec "$cmd" -- "$@"
}

# Helper: Get package names for a recipe
pkg.managers.npm._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "npm"
}

# Search: Check if all packages in a recipe exist in npm registry
pkg.managers.npm.search() {
    pkg.managers.npm.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.npm._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        npm view "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:npm recipes
pkg.managers.npm.install() {
    pkg.managers.npm.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:npm")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "npm")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    npm install -g ${=pkgs}
}

# Upgrade: Handle all upgrade:npm recipes
pkg.managers.npm.upgrade() {
    pkg.managers.npm.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:npm")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "npm")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    npm install -g ${=pkgs}
}
