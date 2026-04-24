# brew_cask.zsh - Homebrew Cask manager implementation

pkg.manager.define "brew_cask" \
    "name=Homebrew Cask" \
    "url=https://formulae.brew.sh/cask/"

pkg.managers.brew_cask.is_available() {
    (( $+commands[brew] ))
}

pkg.managers.brew_cask.enabled() {
    pkg.managers.brew_cask.is_available
}

pkg.managers.brew_cask.check() {
    pkg.managers.brew_cask.is_available || return 1
    local rid="$1"
    local cask=$(pkg.recipe.packages "$rid" "brew_cask")
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

pkg.managers.brew_cask.search() {
    pkg.managers.brew_cask.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" brew_cask):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        brew info --cask "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.brew_cask.install() {
    pkg.managers.brew_cask.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "install:brew_cask") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "brew_cask")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    brew install --cask ${=pkgs}
}

pkg.managers.brew_cask.upgrade() {
    pkg.managers.brew_cask.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "upgrade:brew_cask") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "brew_cask")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    brew upgrade --cask ${=pkgs}
}
