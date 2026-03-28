# src/zsh/functions/managers/flatpak.zsh

pkg.managers.flatpak.is_available() {
    command -v flatpak >/dev/null 2>&1
}

pkg.managers.flatpak.enabled() {
    pkg.managers.flatpak.is_available && return 0
    pkg.actionIsEnabled "$(pkg.recipeAction "$(pkg.managers.flatpak.recipe)")"
}

pkg.managers.flatpak.recipe() {
    echo "flatpak"
}

pkg.managers.flatpak.check() {
    pkg.managers.flatpak.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.flatpak._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        flatpak info "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.flatpak.update() {
    pkg.managers.flatpak.is_available || return 0
    flatpak update --appstream
}

pkg.managers.flatpak.cleanup() {
    pkg.managers.flatpak.is_available || return 0
    flatpak uninstall --unused -y
}

pkg.managers.flatpak.exec() {
    pkg.managers.flatpak.is_available || return 1
    local rid=$1; shift
    local cmd=$1; shift
    flatpak run "$cmd" "$@"
}

pkg.managers.flatpak.setup_repos() {
    pkg.managers.flatpak.is_available || return 0
    if ! flatpak remote-list | grep -q "flathub"; then
        echo "   Adding flathub remote..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        return 1
    fi
    return 0
}

# Helper: Get package names for a recipe
pkg.managers.flatpak._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "flatpak"
}

# Search: Check if all packages in a recipe exist in Flathub
pkg.managers.flatpak.search() {
    pkg.managers.flatpak.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.flatpak._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local all_apps
    all_apps=$(flatpak remote-ls --cached --app flathub --columns=application 2>/dev/null)
    [[ -z "$all_apps" ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        echo "$all_apps" | grep -q "^$pkg$" || return 1
    done
    return 0
}

# Install: Handle all install:flatpak recipes
pkg.managers.flatpak.install() {
    pkg.managers.flatpak.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:flatpak")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "flatpak")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    flatpak install -y flathub ${=pkgs}
}

# Upgrade: Handle all upgrade:flatpak recipes
pkg.managers.flatpak.upgrade() {
    pkg.managers.flatpak.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:flatpak")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "flatpak")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    flatpak update -y ${=pkgs}
}
