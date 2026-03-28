# src/zsh/functions/managers/mise.zsh

pkg.managers.mise.is_available() {
    command -v mise >/dev/null 2>&1
}

pkg.managers.mise.enabled() {
    local rid="$1"
    pkg.managers.mise.is_available && return 0
    # Avoid recursion if checking the mise recipe itself
    [[ "$rid" == "mise" ]] && return 1
    pkg.actionIsEnabled "$(pkg.recipeAction "mise")"
}

pkg.managers.mise.recipe() {
    echo "mise"
}

pkg.managers.mise.check() {
    pkg.managers.mise.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.mise._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg base_pkg satisfied=1
    local installed_list
    installed_list=$(mise ls --global --no-header 2>/dev/null | grep -v "(missing)")

    for pkg in "${pkgs[@]}"; do
        base_pkg="${pkg%@*}"
        # Check if the base package name is in the first column of the installed list
        echo "$installed_list" | awk '{print $1}' | grep -q "^${base_pkg}$" || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

# Install: Handle all install:mise recipes
pkg.managers.mise.install() {
    pkg.managers.mise.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:mise")

    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "mise")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done

    [[ -z "$pkgs" ]] && return 0
    for pkg in "${=pkgs}"; do
        mise use --global "$pkg" || return $?
    done
}

pkg.managers.mise.update() {
    pkg.managers.mise.is_available || return 0
    mise update
}

# Upgrade: Handle all upgrade:mise recipes
pkg.managers.mise.upgrade() {
    pkg.managers.mise.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:mise")

    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "mise")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done

    [[ -z "$pkgs" ]] && return 0
    for pkg in "${=pkgs}"; do
        mise use --global "$pkg" || return $?
    done
}

pkg.managers.mise.cleanup() {
    pkg.managers.mise.is_available || return 0
    mise prune
}

pkg.managers.mise.exec() {
    pkg.managers.mise.is_available || return 1
    local rid=$1; shift
    local cmd=$1; shift
    mise exec "$cmd" -- "$@"
}

# Helper: Get package names for a recipe
pkg.managers.mise._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "mise"
}

# Search: Check if all packages in a recipe exist in mise
# Strips @latest suffix as ls-remote doesn't accept it
pkg.managers.mise.search() {
    pkg.managers.mise.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.mise._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg base_pkg
    for pkg in "${pkgs[@]}"; do
        # Only strip @latest, keep specific versions
        base_pkg="${pkg}"
        [[ "$base_pkg" == *"@latest" ]] && base_pkg="${base_pkg%@latest}"

        # Check if package exists in mise registry
        mise ls-remote "$base_pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}
