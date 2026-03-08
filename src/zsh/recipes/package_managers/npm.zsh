typeset -A recipe=(
    [name]="npm"
    [depends]="node"
    [proxy]=true
    [installer]=true
    [installer_precedence]=13
    [installer_install]='
        local pkgs=($(pkg.field "$1" npm))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec npm install -g "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" npm))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec npm install -g "${pkgs[@]}"
    '
    # npm has no separate cache refresh; registry is queried on demand
    [installer_check]='
        local pkgs=($(pkg.field "$1" npm)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg.exec npm list -g "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    [installer_exec]='
        local pkgs=($(pkg.field "$1" npm))
        shift 2
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec npm exec "${pkgs[@]}" "$@"
    '
)
