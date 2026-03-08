typeset -A recipe=(
    [name]="npx"
    [depends]="node"
    [proxy]=true
    [installer]=true
    [installer_precedence]=13
    [installer_install]='
        return 0
    '
    [installer_upgrade]='
        return 0
    '
    [installer_check]='
        return 0
    '
    [installer_exec]='
        local pkgs=($(pkg.field "$1" npx))
        shift 2
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec npx -y "${pkgs[@]}" "$@"
    '
)
