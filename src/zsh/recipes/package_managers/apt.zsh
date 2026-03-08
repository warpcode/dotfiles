typeset -A recipe=(
    [name]="apt"
    [provides]="apt"
    [installer]=true
    [installer_precedence]=6
    [installer_install]='
        local pkgs=($(pkg.field "$1" apt))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        sudo apt install -y "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" apt))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        sudo apt install --only-upgrade -y "${pkgs[@]}"
    '
    [installer_repo_update]='sudo apt update -qq'
    [installer_check]='
        local pkgs=($(pkg.field "$1" apt)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            dpkg-query -W -f='\''${Status}'\'' "$pkg" 2>/dev/null | grep -q "ok installed" || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '

    # Registration of extensions
    [installer_pre_install_ext]="key repo"

    # Implementation: installer_ext_key <rid> <key_url|keyring_name>
    [installer_ext_key]='
        local rid=$1
        local val=$(pkg.field "$rid" "apt_key")
        [[ -z "$val" ]] && return 0
        local key_url="${val%%|*}"
        local keyring_name="${val#*|}"
        local keyring_path="/usr/share/keyrings/$keyring_name"

        # Interpolate variables in URL
        local distro=$(lsb_release -is 2>/dev/null | tr "[:upper:]" "[:lower:]" || echo "debian")
        key_url="${key_url//\%DISTRO\%/$distro}"

        if [[ ! -f "$keyring_path" ]]; then
            echo "   Downloading GPG key for $rid..."
            curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring_path" --yes
            return 2 # Dirty
        fi
    '

    # Implementation: installer_ext_repo <rid> <keyring_name|repo_line>
    [installer_ext_repo]='
        local rid=$1
        local val=$(pkg.field "$rid" "apt_repo")
        [[ -z "$val" ]] && return 0
        local keyring_name="${val%%|*}"
        local repo_line="${val#*|}"
        local keyring_path="/usr/share/keyrings/$keyring_name"

        # Interpolate variables
        local codename=$(lsb_release -cs 2>/dev/null || echo "stable")
        local arch=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
        local distro=$(lsb_release -is 2>/dev/null | tr "[:upper:]" "[:lower:]" || echo "debian")

        repo_line="${repo_line//\%CODENAME\%/$codename}"
        repo_line="${repo_line//\%ARCH\%/$arch}"
        repo_line="${repo_line//\%DISTRO\%/$distro}"
        repo_line="${repo_line//\%KEYRING\%/$keyring_path}"

        local list_file="/etc/apt/sources.list.d/${rid}.list"
        local existing=""
        [[ -f "$list_file" ]] && existing=$(cat "$list_file")

        if [[ "$existing" != "$repo_line" ]]; then
            echo "   Configuring apt source for $rid..."
            echo "$repo_line" | sudo tee "$list_file" >/dev/null
            return 2 # Dirty
        fi
    '
)
