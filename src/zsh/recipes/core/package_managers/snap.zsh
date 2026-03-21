typeset -A recipe=(
    [name]="snap"
    [provides]="snap"
    [installer]=true
    [installer_precedence]=5
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" snap))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        snap install "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" snap))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        snap refresh "${pkgs[@]}"
    }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" snap)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            snap list "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'
)
