typeset -A recipe=(
    [name]="brew-cask"
    [depends]="brew"
    [proxy]=true
    [installer]=true
    [installer_precedence]=2
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" brew-cask))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        brew install --cask "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" brew-cask))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        brew upgrade --cask "${pkgs[@]}"
    }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" brew-cask)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            brew list --cask "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'
)
