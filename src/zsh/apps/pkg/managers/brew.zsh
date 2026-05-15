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

    local pkg
    local -a pkg_names
    for pkg in "${pkgs[@]}"; do
        pkg_names+=( "${${pkg%% --HEAD}%% *}" )
    done

    brew list "${pkg_names[@]}" >/dev/null 2>&1 || return 1
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

    brew info "${pkgs[@]}" >/dev/null 2>&1 || return 1
    return 0
}

pkg.managers.brew.install() {
    pkg.managers.brew.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "install:brew") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "brew")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    brew install ${=pkgs}
}

pkg.managers.brew.upgrade() {
    pkg.managers.brew.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "upgrade:brew") )
    for rid in "${rids[@]}"; do
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
