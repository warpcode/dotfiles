typeset -A recipe=(
    [name]="custom_install"
    [provides]="true"
    [installer]=true
    [installer_precedence]=999
    # installer_install receives: $1=rid
    [installer_install]='
        pkg.hook "$1" "custom_install" "$1" || return 1
        return 0
    '
    # installer_check receives: $1=rid
    [installer_check]='
        pkg.hook "$1" "custom_install_check" "$1" || return 1
        return 0
    '
    [installer_enabled]='
        return 0
    '
)
