# src/zsh/functions/managers/apt.zsh

pkg.managers.apt.is_available() {
    command -v apt-get >/dev/null 2>&1
}

pkg.managers.apt.enabled() {
    pkg.managers.apt.is_available
}

pkg.managers.apt.check() {
    pkg.managers.apt.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.apt._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg satisfied=1
    for pkg in "${pkgs[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" || { satisfied=0; break; }
    done
    return $((1 - satisfied))
}

pkg.managers.apt.update() {
    pkg.managers.apt.is_available || return 0
    sudo apt-get update -qq
}

pkg.managers.apt.cleanup() {
    pkg.managers.apt.is_available || return 0
    sudo apt-get autoremove -y
    sudo apt-get clean
}

# Helper: Get package names for a recipe
pkg.managers.apt._get_pkgs() {
    local rid="$1"
    pkg.recipePackages "$rid" "apt"
}

# Search: Check if all packages in a recipe exist in apt repositories
pkg.managers.apt.search() {
    pkg.managers.apt.is_available || return 1
    local rid="$1"
    local pkgs_str pkgs
    pkgs_str=$(pkg.managers.apt._get_pkgs "$rid")
    [[ -z "$pkgs_str" ]] && return 1
    pkgs=(${=pkgs_str})
    [[ ${#pkgs[@]} -eq 0 ]] && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        apt-cache show "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Install: Handle all install:apt recipes
pkg.managers.apt.install() {
    pkg.managers.apt.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "install:apt")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "apt")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo apt-get install -y ${=pkgs}
}

# Upgrade: Handle all upgrade:apt recipes
pkg.managers.apt.upgrade() {
    pkg.managers.apt.is_available || return 0
    local recipes pkgs="" rid
    recipes=$(pkg.recipesByAction "upgrade:apt")
    
    for rid in "${=recipes}"; do
        local pkg=$(pkg.recipePackages "$rid" "apt")
        [[ -n "$pkg" ]] && pkgs="${pkgs:+$pkgs }$pkg"
    done
    
    [[ -z "$pkgs" ]] && return 0
    sudo apt-get install --only-upgrade -y ${=pkgs}
}

# Setup repositories: Add apt keys and repos idempotently
pkg.managers.apt.setup_repos() {
    # Check if apt is available
    pkg.managers.apt.is_available || return 0

    local changed=0
    local key val key_url keyring_name keyring_path repo_key repo_line
    local list_file existing placeholder replacement

    # Pre-compute system values for placeholder substitution
    local codename=$(lsb_release -cs 2>/dev/null || echo stable)
    local arch=$(dpkg --print-architecture 2>/dev/null || echo amd64)
    local distro=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo debian)

    # Collect unique apt_key values
    typeset -A seen_keys
    for key in ${(k)pkg_recipes}; do
        [[ "$key" == *":apt_key" ]] || continue
        val="${pkg_recipes[$key]}"
        [[ -n "${seen_keys[$val]}" ]] && continue
        seen_keys[$val]=1

        # Parse key_url and keyring_name
        key_url="${val%%|*}"
        keyring_name="${val#*|}"
        keyring_path="/etc/apt/keyrings/$keyring_name"

        # Build placeholder substitution map
        typeset -A placeholders=(
            [%CODENAME%]="$codename"
            [%ARCH%]="$arch"
            [%DISTRO%]="$distro"
            [%KEYRING%]="$keyring_path"
        )

        # Apply all placeholder substitutions
        for placeholder replacement in ${(kv)placeholders}; do
            key_url="${key_url//$placeholder/$replacement}"
        done

        # Add GPG key idempotently (direct download, no gpg processing)
        # Ensure keyrings directory exists
        sudo install -dm 755 /etc/apt/keyrings 2>/dev/null
        
        # Download key if it doesn't exist
        if [[ ! -f "$keyring_path" ]]; then
            echo "   Adding GPG key: $keyring_name"
            if sudo curl -fsSL "$key_url" -o "$keyring_path" 2>/dev/null; then
                sudo chmod a+r "$keyring_path"
                changed=1
            else
                echo "   WARNING: Failed to download GPG key from $key_url" >&2
            fi
        fi
    done

    # Collect unique apt_repo values
    typeset -A seen_repos
    for repo_key in ${(k)pkg_recipes}; do
        [[ "$repo_key" == *":apt_repo" ]] || continue
        val="${pkg_recipes[$repo_key]}"
        [[ -n "${seen_repos[$val]}" ]] && continue
        seen_repos[$val]=1

        # Extract package name from key (e.g., "docker:apt_repo" → "docker")
        local package_name="${repo_key%:apt_repo}"

        # Parse repo details
        keyring_name="${val%%|*}"
        repo_line="${val#*|}"
        keyring_path="/etc/apt/keyrings/$keyring_name"

        # Build placeholder substitution map
        typeset -A placeholders=(
            [%CODENAME%]="$codename"
            [%ARCH%]="$arch"
            [%DISTRO%]="$distro"
            [%KEYRING%]="$keyring_path"
        )

        # Apply all placeholder substitutions
        for placeholder replacement in ${(kv)placeholders}; do
            repo_line="${repo_line//$placeholder/$replacement}"
        done

        # Add repo source idempotently
        local list_file="/etc/apt/sources.list.d/dotfiles-${package_name}.list"
        if [[ -f "$list_file" ]]; then
            local existing=$(cat "$list_file" 2>/dev/null)
            [[ "$existing" == "$repo_line" ]] && continue
        fi

        echo "   Adding apt repo: $package_name"
        echo "$repo_line" | sudo tee "$list_file" >/dev/null && changed=1
    done

    # Update cache if repos were added
    [[ $changed -eq 1 ]] && sudo apt-get update -qq
}
