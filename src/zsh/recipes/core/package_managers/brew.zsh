typeset -A recipe=(
    [name]="brew"
    [provides]="brew"
    [installer]=true
    [installer_precedence]=1
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" brew))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        brew install "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" brew))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        brew upgrade "${pkgs[@]}"
    }'
    [installer_repo_update]='fn() { brew update; }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" brew)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            brew list "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'

    # Registration of extensions
    [installer_pre_install_ext]="tap"

    # Implementation: installer_ext_tap <rid> <tap_name>
    [installer_ext_tap]='fn() {
        local rid=$1
        local val=$(pkg.field "$rid" "brew_tap")
        [[ -z "$val" ]] && return 0
        for t in ${=val}; do
            if ! brew tap | grep -q "^$t$"; then
                echo "   Tapping $t..."
                brew tap "$t"
                return 2 # Dirty
            fi
        done
    }'
)
