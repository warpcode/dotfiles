# src/zsh/functions/managers/snap.zsh

pkg.managers.snap.is_available() {
    command -v snap >/dev/null 2>&1
}

pkg.managers.snap.enabled() {
    pkg.managers.snap.is_available
}

pkg.managers.snap.check() {
    pkg.managers.snap.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.snap._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg pkg_name satisfied=1
    for pkg in "${pkgs[@]}"; do
        # Strip --classic flag for checking
        pkg_name="${pkg%% --classic}"
        pkg_name="${pkg_name%% *}"
        snap list "$pkg_name" >/dev/null 2>&1 || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.snap.update() {
    return 0
}

pkg.managers.snap.cleanup() {
    return 0
}

# Helper: Get package names for a recipe
pkg.managers.snap._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "snap"
}

# Search: Check if all packages in a recipe exist in Snap Store
pkg.managers.snap.search() {
    pkg.managers.snap.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.snap._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg pkg_name
    for pkg in "${pkgs[@]}"; do
        # Strip --classic for search
        pkg_name="${pkg%% --classic}"
        pkg_name="${pkg_name%% *}"
        snap info "$pkg_name" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:snap recipes
pkg.managers.snap.install() {
    pkg.managers.snap.is_available || return 0
    local recipes pkgs="" rid pkg pkg_name
    recipes=$(pkg.recipesByAction "install:snap")
    
    for rid in "${=recipes}"; do
        pkg=$(pkg.recipePackages "$rid" "snap")
        [[ -z "$pkg" ]] && continue
        
        # Handle --classic flag
        if [[ "$pkg" == *" --classic"* ]]; then
            pkg_name="${pkg%% --classic*}"
            sudo snap install "$pkg_name" --classic || return $?
        else
            sudo snap install "$pkg" || return $?
        fi
    done
}

# Upgrade: Handle all upgrade:snap recipes
pkg.managers.snap.upgrade() {
    pkg.managers.snap.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:snap")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "snap")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo snap refresh ${=pkgs}
}
