# flatpak.zsh - Flatpak manager implementation

pkg.manager.define "flatpak" \
    "name=Flatpak" \
    "url=https://flatpak.org/"

pkg.managers.flatpak.is_available() {
    (( $+commands[flatpak] ))
}

pkg.managers.flatpak.enabled() {
    pkg.managers.flatpak.is_available && return 0
    pkg.recipe.action_is_enabled "$(pkg.recipe.action "flatpak")"
}

pkg.managers.flatpak.check() {
    pkg.managers.flatpak.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" flatpak):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        flatpak info "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
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
    local rid=$1 cmd=$2; shift 2
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

pkg.managers.flatpak.search() {
    pkg.managers.flatpak.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" flatpak):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local all_apps=$(flatpak remote-ls --cached --app flathub --columns=application 2>/dev/null)
    [[ -z "$all_apps" ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        echo "$all_apps" | grep -q "^$pkg$" || return 1
    done
    return 0
}

pkg.managers.flatpak.install() {
    pkg.managers.flatpak.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "install:flatpak") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "flatpak")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    flatpak install -y flathub ${=pkgs}
}

pkg.managers.flatpak.upgrade() {
    pkg.managers.flatpak.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "upgrade:flatpak") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "flatpak")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    flatpak update -y ${=pkgs}
}
