# src/zsh/functions/managers/dnf.zsh

pkg.managers.dnf.is_available() {
    command -v dnf >/dev/null 2>&1
}

pkg.managers.dnf.enabled() {
    pkg.managers.dnf.is_available
}

pkg.managers.dnf.check() {
    pkg.managers.dnf.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.dnf._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        rpm -q "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.dnf.update() {
    pkg.managers.dnf.is_available || return 0
    sudo dnf makecache
}

pkg.managers.dnf.cleanup() {
    pkg.managers.dnf.is_available || return 0
    sudo dnf autoremove -y
    sudo dnf clean all
}

# Helper: Get package names for a recipe
pkg.managers.dnf._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "dnf"
}

# Search: Check if all packages in a recipe exist in DNF repositories
pkg.managers.dnf.search() {
    pkg.managers.dnf.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.dnf._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        dnf list available "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:dnf recipes
pkg.managers.dnf.install() {
    pkg.managers.dnf.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:dnf")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "dnf")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo dnf install -y ${=pkgs}
}

# Upgrade: Handle all upgrade:dnf recipes
pkg.managers.dnf.upgrade() {
    pkg.managers.dnf.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:dnf")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "dnf")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo dnf upgrade -y ${=pkgs}
}

# Setup repositories: Add dnf repos and copr repos idempotently
pkg.managers.dnf.setup_repos() {
    # Check if dnf is available
    pkg.managers.dnf.is_available || return 0

    local changed=0
    local repo_key val repo_filename

    # Collect unique dnf_repo values
    typeset -A seen_repos
    for repo_key in ${(k)pkg_recipes}; do
        [[ "$repo_key" == *":dnf_repo" ]] || continue
        val="${pkg_recipes[$repo_key]}"
        [[ -n "${seen_repos[$val]}" ]] && continue
        seen_repos[$val]=1
        
        # Add dnf repo
        repo_filename="${val:t}"
        if [[ ! -f "/etc/yum.repos.d/$repo_filename" ]]; then
            echo "   Adding dnf repo: $repo_filename"
            sudo dnf config-manager --add-repo "$val" && changed=1
        fi
    done
    
    # Collect unique dnf_copr values
    typeset -A seen_coprs
    for repo_key in ${(k)pkg_recipes}; do
        [[ "$repo_key" == *":dnf_copr" ]] || continue
        val="${pkg_recipes[$repo_key]}"
        [[ -n "${seen_coprs[$val]}" ]] && continue
        seen_coprs[$val]=1
        
        # Enable copr repo
        echo "   Enabling copr repo: $val"
        sudo dnf copr enable -y "$val" && changed=1
    done
    
    # Update cache if repos were added
    [[ $changed -eq 1 ]] && sudo dnf makecache
}
