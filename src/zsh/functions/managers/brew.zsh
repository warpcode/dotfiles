# src/zsh/functions/managers/brew.zsh

pkg.managers.brew.is_available() {
    command -v brew >/dev/null 2>&1
}

pkg.managers.brew.enabled() {
    pkg.managers.brew.is_available
}

pkg.managers.brew.check() {
    pkg.managers.brew.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.brew._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg pkg_name satisfied=1
    for pkg in "${pkgs[@]}"; do
        # Strip --HEAD flag for checking
        pkg_name="${pkg%% --HEAD}"
        pkg_name="${pkg_name%% *}"
        brew list "$pkg_name" >/dev/null 2>&1 || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.brew.update() {
    pkg.managers.brew.is_available || return 0
    brew update
}

pkg.managers.brew.cleanup() {
    pkg.managers.brew.is_available || return 0
    brew cleanup
}

# Helper: Get package names for a recipe
pkg.managers.brew._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "brew"
}

# Search: Check if all packages in a recipe exist in Homebrew
pkg.managers.brew.search() {
    pkg.managers.brew.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.brew._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        brew info "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:brew recipes
pkg.managers.brew.install() {
    pkg.managers.brew.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:brew")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "brew")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    brew install ${=pkgs}
}

# Upgrade: Handle all upgrade:brew recipes
pkg.managers.brew.upgrade() {
    pkg.managers.brew.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:brew")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "brew")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    brew upgrade ${=pkgs}
}

# Setup repositories: Add brew taps idempotently
pkg.managers.brew.setup_repos() {
    # Check if brew is available
    pkg.managers.brew.is_available || return 0

    local changed=0
    local tap_key val t

    # Collect unique brew_tap values
    typeset -A seen_taps
    for tap_key in ${(k)pkg_recipes}; do
        [[ "$tap_key" == *":brew_tap" ]] || continue
        val="${pkg_recipes[$tap_key]}"
        for t in ${=val}; do
            [[ -n "${seen_taps[$t]}" ]] && continue
            seen_taps[$t]=1
            
            # Tap repo idempotently
            if ! brew tap | grep -q "^$t$"; then
                echo "   Tapping $t"
                brew tap "$t" && changed=1
            fi
        done
    done
    
    # Update cache if taps were added
    [[ $changed -eq 1 ]] && brew update
}
