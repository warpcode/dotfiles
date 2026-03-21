typeset -A recipe=(
    [name]="uv"
    [provides]="uv"
    [mise]="uv"
    [installer]=true
    [installer_precedence]=11
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" uv))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec uv tool install "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" uv))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec uv tool upgrade "${pkgs[@]}"
    }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" uv)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg.exec uv tool list | grep -q "^$pkg " || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'
)
