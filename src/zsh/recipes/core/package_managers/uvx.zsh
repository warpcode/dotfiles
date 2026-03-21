typeset -A recipe=(
    [name]="uvx"
    [provides]="uvx"
    [depends]="uv"
    [proxy]=true
    [installer]=true
    [installer_precedence]=12
    [installer_install]='fn() {
        return 0
    }'
    [installer_upgrade]='fn() {
        return 0
    }'
    [installer_check]='fn() {
        return 0
    }'
    [installer_exec]='fn() {
        local pkgs=($(pkg.field "$1" uvx))
        shift 2
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec uvx "${pkgs[@]}" "$@"
    }'
)
