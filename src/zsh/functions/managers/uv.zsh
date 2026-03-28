# src/zsh/functions/managers/uv.zsh

pkg.managers.uv.is_available() {
    command -v uv >/dev/null 2>&1
}

pkg.managers.uv.enabled() {
    pkg.managers.uv.is_available && return 0
    pkg.actionIsEnabled "$(pkg.recipeAction "$(pkg.managers.uv.recipe)")"
}

pkg.managers.uv.recipe() {
    echo "uv"
}

pkg.managers.uv.check() {
    pkg.managers.uv.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.uv._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        uv tool list | grep -q "^$pkg " || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.uv.update() {
    pkg.managers.uv.is_available || return 0
    return 0
}

pkg.managers.uv.cleanup() {
    pkg.managers.uv.is_available || return 0
    uv cache clean
}

# Helper: Get package names for a recipe
pkg.managers.uv._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "uv"
}

# Search: Check if all packages in a recipe exist in PyPI
pkg.managers.uv.search() {
    pkg.managers.uv.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.uv._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        uv pip index versions "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:uv recipes
pkg.managers.uv.install() {
    pkg.managers.uv.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:uv")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "uv")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    uv tool install ${=pkgs}
}

# Upgrade: Handle all upgrade:uv recipes
pkg.managers.uv.upgrade() {
    pkg.managers.uv.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:uv")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "uv")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    uv tool upgrade ${=pkgs}
}
