# src/zsh/functions/managers/brew-cask.zsh

pkg.managers.brew_cask.is_available() {
    pkg.managers.brew.is_available
}

pkg.managers.brew_cask.enabled() {
    pkg.managers.brew_cask.is_available
}

pkg.managers.brew_cask.check() {
    pkg.managers.brew_cask.is_available || return 1
    local rid="$1"
    local cask=$(pkg.recipePackages "$rid" "brew_cask")
    [[ -z "$cask" ]] && return 1

    brew list --cask "$cask" >/dev/null 2>&1
}

pkg.managers.brew_cask.update() {
    pkg.managers.brew_cask.is_available || return 0
    brew update
}

pkg.managers.brew_cask.cleanup() {
    pkg.managers.brew_cask.is_available || return 0
    brew cleanup
}

# Search: Check if all casks in a recipe exist in Homebrew Cask
pkg.managers.brew_cask.search() {
    pkg.managers.brew_cask.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.brew_cask._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        brew info --cask "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:brew_cask recipes
pkg.managers.brew_cask.install() {
    pkg.managers.brew_cask.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:brew_cask")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "brew_cask")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    brew install --cask ${=pkgs}
}

# Upgrade: Handle all upgrade:brew_cask recipes
pkg.managers.brew_cask.upgrade() {
    pkg.managers.brew_cask.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:brew_cask")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "brew_cask")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    brew upgrade --cask ${=pkgs}
}
