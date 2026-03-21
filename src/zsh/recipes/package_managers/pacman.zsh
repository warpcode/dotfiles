typeset -A recipe=(
    [name]="pacman"
    [provides]="pacman"
    [installer]=true
    [installer_precedence]=8
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" pacman))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        sudo pacman -S --noconfirm "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" pacman))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        sudo pacman -S --noconfirm "${pkgs[@]}"
    }'
    [installer_repo_update]='fn() { sudo pacman -Sy; }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" pacman)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pacman -Qq "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'
)
