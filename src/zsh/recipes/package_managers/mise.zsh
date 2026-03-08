typeset -A recipe=(
    [name]="mise"
    [provides]="mise"
    [depends]='curl'

    # Installation
    [brew]="mise"
    [custom_install]='curl https://mise.run | sh'
    [custom_check]='command -v mise >/dev/null'
    [custom_update]='curl https://mise.run | sh'
    [custom_enabled]='[[ "$OSTYPE" == linux* && ! _os_is_termux ]]'

    # Installer setup
    [installer]=true
    [installer_precedence]=10
    [installer_install]='
        local pkgs=($(pkg.field "$1" mise))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        mise install "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" mise))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        mise upgrade "${pkgs[@]}"
    '
    [installer_repo_update]='mise plugins update'
    [installer_check]='
        local pkgs=($(pkg.field "$1" mise)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            mise where "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    [installer_enabled]='[[ "$OSTYPE" == darwin* || ( "$OSTYPE" == linux* && ! _os_is_termux ) ]]'
)


