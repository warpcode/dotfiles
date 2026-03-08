typeset -A recipe=(
    [name]="pkg"
    [provides]="pkg"
    [installer]=true
    [installer_precedence]=3
    [installer_install]='
        local pkgs=($(pkg.field "$1" pkg))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg install -y "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" pkg))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg upgrade "${pkgs[@]}"
    '
    [installer_repo_update]='pkg update'
    [installer_check]='
        local pkgs=($(pkg.field "$1" pkg)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg info "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
)
