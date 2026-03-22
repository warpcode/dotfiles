typeset -A recipe=(
    [name]="mise"
    [provides]="mise"
    [depends]='curl'

    # Installation
    [brew]="mise"
    [custom_install]='fn() { pkg.exec curl https://mise.run | sh; }'
    [custom_install_check]='fn() { command -v mise >/dev/null; }'
    [custom_install_update]='fn() { pkg.exec curl https://mise.run | sh; }'
    [custom_install_enabled]='fn() {
        [[ "$OSTYPE" != linux* ]] && return 1
        _os_is_termux && return 1
        return 0
    }'

    # Installer setup
    [installer]=true
    [installer_precedence]=10
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" mise))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec mise use --global "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" mise))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec mise use --global "${pkgs[@]}"
    }'
    [installer_repo_update]='fn() { mise plugins update; }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" mise)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg.exec mise ls --installed --no-header --global | awk -v spec="$pkg" '\''
                $1"@"$NF == spec { found=1 }
                END { exit !found }
            '\'' >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'
    [installer_enabled]='fn() {
        # macOS: always enable
        [[ "$OSTYPE" == darwin* ]] && return 0
        # Linux: enable unless termux
        [[ "$OSTYPE" != linux* ]] && return 1
        # Check for termux only if function is available
        typeset -f _os_is_termux >/dev/null && _os_is_termux && return 1
        return 0
    }'
    [installer_exec]='fn() {
        local pkgs=($(pkg.field "$1" mise))
        shift
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec mise exec --quiet "${pkgs[@]}" -- "$@"
    }'
    [installer_post_install]='fn() {
        if command -v mise >/dev/null; then
            eval "$(mise activate zsh)"
        fi
    }'
)


