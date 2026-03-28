# src/zsh/functions/managers/pacman.zsh

pkg.managers.pacman.is_available() {
    command -v pacman >/dev/null 2>&1
}

pkg.managers.pacman.enabled() {
    pkg.managers.pacman.is_available
}

pkg.managers.pacman.check() {
    pkg.managers.pacman.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.pacman._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.pacman.update() {
    pkg.managers.pacman.is_available || return 0
    sudo pacman -Sy
}

pkg.managers.pacman.cleanup() {
    pkg.managers.pacman.is_available || return 0
    sudo pacman -Sc --noconfirm
}

# Helper: Get package names for a recipe
pkg.managers.pacman._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "pacman"
}

# Search: Check if all packages in a recipe exist in Pacman repositories
pkg.managers.pacman.search() {
    pkg.managers.pacman.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.pacman._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        pacman -Si "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:pacman recipes
pkg.managers.pacman.install() {
    pkg.managers.pacman.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:pacman")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "pacman")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo pacman -S --noconfirm ${=pkgs}
}

# Upgrade: Handle all upgrade:pacman recipes
pkg.managers.pacman.upgrade() {
    pkg.managers.pacman.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:pacman")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "pacman")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo pacman -S --noconfirm ${=pkgs}
}
