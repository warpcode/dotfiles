typeset -A recipe=(
    [name]="npx"
    [depends]="node"
    [proxy]=true
    [installer]=true
    [installer_precedence]=13
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
        local pkgs=($(pkg.field "$1" npx))
        shift 2
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec npx -y "${pkgs[@]}" "$@"
    }'
)
