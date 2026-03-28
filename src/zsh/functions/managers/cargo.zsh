# src/zsh/functions/managers/cargo.zsh

pkg.managers.cargo.is_available() {
    command -v cargo >/dev/null 2>&1
}

pkg.managers.cargo.enabled() {
    pkg.managers.cargo.is_available && return 0
    pkg.actionIsEnabled "$(pkg.recipeAction "$(pkg.managers.cargo.recipe)")"
}

pkg.managers.cargo.recipe() {
    echo "cargo"
}

pkg.managers.cargo.check() {
    pkg.managers.cargo.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.cargo._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        cargo install --list | grep -q "^$pkg " || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.cargo.update() {
    return 0
}

pkg.managers.cargo.cleanup() {
    return 0
}

# Helper: Get package names for a recipe
pkg.managers.cargo._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "cargo"
}

# Search: Check if all packages in a recipe exist in crates.io
pkg.managers.cargo.search() {
    pkg.managers.cargo.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.cargo._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        cargo search --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg = " || return 1
    done
    return 0
}

# Install: Handle all install:cargo recipes
pkg.managers.cargo.install() {
    pkg.managers.cargo.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:cargo")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "cargo")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    cargo install ${=pkgs}
}

# Upgrade: Handle all upgrade:cargo recipes
pkg.managers.cargo.upgrade() {
    pkg.managers.cargo.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:cargo")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "cargo")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    cargo install ${=pkgs}
}
