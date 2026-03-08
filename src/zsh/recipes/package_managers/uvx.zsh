typeset -A recipe=(
    [name]="uvx"
    [provides]="uvx"
    [depends]="uv"
    [proxy]=true
    [installer]=true
    [installer_precedence]=12
    [installer_install]='
        local pkgs=($(pkg.field "$1" uvx))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        uvx tool install "${pkgs[@]}"
    '
)
