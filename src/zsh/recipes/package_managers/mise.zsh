typeset -A recipe=(
    [name]="mise"
    [provides]="mise"
    [depends]='curl'

    # Installation
    [brew]="mise"
    [custom_install]='pkg.exec curl https://mise.run | sh'
    [custom_install_check]='command -v mise >/dev/null'
    [custom_install_update]='pkg.exec curl https://mise.run | sh'
    [custom_install_enabled]='[[ "$OSTYPE" == linux* && ! _os_is_termux ]]'

    # Installer setup
    [installer]=true
    [installer_precedence]=10
    [installer_install]='
        local pkgs=($(pkg.field "$1" mise))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec mise install "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" mise))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec mise upgrade "${pkgs[@]}"
    '
    [installer_repo_update]='mise plugins update'
    [installer_check]='
        local pkgs=($(pkg.field "$1" mise)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg.exec mise where "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    [installer_enabled]='[[ "$OSTYPE" == darwin* || ( "$OSTYPE" == linux* && ! _os_is_termux ) ]]'
    [installer_exec]='
        local pkgs=($(pkg.field "$1" mise))
        shift
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec mise exec "${pkgs[@]}" -- "$@"
    '
)


