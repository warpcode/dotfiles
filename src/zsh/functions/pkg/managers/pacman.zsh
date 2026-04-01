# pacman.zsh - Pacman manager implementation

pkg.managers.pacman.is_available() {
    (( $+commands[pacman] ))
}

pkg.managers.pacman.enabled() {
    pkg.managers.pacman.is_available
}

pkg.managers.pacman.check() {
    pkg.managers.pacman.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:pacman]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.pacman.update() {
    pkg.managers.pacman.is_available || return 0
    sudo pacman -Sy
}

pkg.managers.pacman.cleanup() {
    pkg.managers.pacman.is_available || return 0
    sudo pacman -Sc --noconfirm
}

pkg.managers.pacman.search() {
    pkg.managers.pacman.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[${rid}:pacman]:-${pkg_recipes[${rid}:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        pacman -Si "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.pacman.install() {
    pkg.managers.pacman.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "install:pacman"); do
        local p=$(pkg.recipe_packages "$rid" "pacman")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    sudo pacman -S --noconfirm ${=pkgs}
}

pkg.managers.pacman.upgrade() {
    pkg.managers.pacman.install
}
