typeset -A recipe=(
    [name]="uvx"
    [provides]="uvx"
    [depends]="uv"
    [proxy]=true
    [installer]=true
    [installer_precedence]=12
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" uvx))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec uvx tool install "${pkgs[@]}"
    }'
)
