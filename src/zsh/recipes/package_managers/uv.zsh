typeset -A recipe=(
    [name]="uv"
    [provides]="uv"
    [mise]="uv"
    [installer]=true
    [installer_precedence]=11
    [installer_install]='
        local pkgs=($(pkg.field "$1" uv))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        uv tool install "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" uv))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        uv tool upgrade "${pkgs[@]}"
    '
    [installer_check]='
        local pkgs=($(pkg.field "$1" uv)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            uv tool list | grep -q "^$pkg " || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
)
