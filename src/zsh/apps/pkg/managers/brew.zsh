# brew.zsh - Homebrew manager implementation

pkg.manager.define "brew" \
    "name=Homebrew" \
    "url=https://brew.sh"

pkg.managers.brew.is_available() {
    (( $+commands[brew] ))
}

pkg.managers.brew.enabled() {
    pkg.managers.brew.is_available
}

pkg.managers.brew.check() {
    pkg.managers.brew.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" brew):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg pkg_name
    for pkg in "${pkgs[@]}"; do
        pkg_name="${${pkg%% --HEAD}%% *}"
        brew list "$pkg_name" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.brew.update() {
    pkg.managers.brew.is_available || return 0
    brew update
}

pkg.managers.brew.cleanup() {
    pkg.managers.brew.is_available || return 0
    brew cleanup
}

pkg.managers.brew.search() {
    pkg.managers.brew.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" brew):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        brew info "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.brew.install() {
    pkg.managers.brew.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipe.by_action "install:brew"); do
        local p=$(pkg.recipe.packages "$rid" "brew")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    brew install ${=pkgs}
}

pkg.managers.brew.upgrade() {
    pkg.managers.brew.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipe.by_action "upgrade:brew"); do
        local p=$(pkg.recipe.packages "$rid" "brew")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    brew upgrade ${=pkgs}
}

pkg.managers.brew.setup_repos() {
    pkg.managers.brew.is_available || return 0
    local changed=0 rid val t
    typeset -A seen_taps
    for rid in $(registry.list pkg); do
        val="$(pkg.recipe.get "$rid" "brew_tap")"
        [[ -z "$val" ]] && continue
        for t in ${=val}; do
            [[ -n "${seen_taps[$t]}" ]] && continue
            seen_taps[$t]=1
            if ! brew tap | grep -q "^$t$"; then
                echo "   Tapping $t"
                brew tap "$t" && changed=1
            fi
        done
    done
    [[ $changed -eq 1 ]] && brew update
}
