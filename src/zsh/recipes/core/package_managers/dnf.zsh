typeset -A recipe=(
    [name]="dnf"
    [provides]="dnf"
    [installer]=true
    [installer_precedence]=7
    [installer_install]='fn() {
        local pkgs=($(pkg.field "$1" dnf))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        sudo dnf install -y "${pkgs[@]}"
    }'
    [installer_upgrade]='fn() {
        local pkgs=($(pkg.field "$1" dnf))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        sudo dnf upgrade -y "${pkgs[@]}"
    }'
    [installer_repo_update]='fn() { sudo dnf makecache; }'
    [installer_check]='fn() {
        local pkgs=($(pkg.field "$1" dnf)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            rpm -q "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    }'

    # Registration of extensions
    [installer_pre_install_ext]="repo"

    # Implementation: installer_ext_repo <rid> <repo_url>
    [installer_ext_repo]='fn() {
        local rid=$1
        local config=$(pkg.field "$rid" "dnf_repo")
        [[ -z "$config" ]] && return 0
        local repo_filename="${config:t}"
        if [[ ! -f "/etc/yum.repos.d/$repo_filename" ]]; then
            echo "   Adding dnf repo for $rid..."
            sudo dnf config-manager --add-repo "$config"
            return 2 # Dirty
        fi
    }'
)
