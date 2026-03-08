typeset -A recipe=(
    [name]="composer"
    [provides]="composer"
    [installer]=true
    [installer_precedence]=15
    [installer_install]='
        local pkgs=($(pkg.field "$1" composer))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        composer global require "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" composer))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        composer global require "${pkgs[@]}"
    '
    [installer_check]='
        local pkgs=($(pkg.field "$1" composer)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            composer global show "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    # composer itself can be installed via various methods:
    [apt]="composer"
    [dnf]="composer"
    [brew]="composer"
    [depends]="php"
)
