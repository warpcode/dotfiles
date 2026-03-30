# apt.zsh - APT manager implementation

pkg.managers.apt.is_available() {
    (( $+commands[apt-get] ))
}

pkg.managers.apt.enabled() {
    pkg.managers.apt.is_available
}

pkg.managers.apt.check() {
    pkg.managers.apt.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[$rid:apt]:-${pkg_recipes[$rid:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" || return 1
    done
    return 0
}

pkg.managers.apt.update() {
    pkg.managers.apt.is_available || return 0
    sudo apt-get update -qq
}

pkg.managers.apt.cleanup() {
    pkg.managers.apt.is_available || return 0
    sudo apt-get autoremove -y && sudo apt-get clean
}

pkg.managers.apt.search() {
    pkg.managers.apt.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=pkg_recipes[$rid:apt]:-${pkg_recipes[$rid:package]}} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        apt-cache show "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.apt.install() {
    pkg.managers.apt.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "install:apt"); do
        local p=$(pkg.recipe_packages "$rid" "apt")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    sudo apt-get install -y ${=pkgs}
}

pkg.managers.apt.upgrade() {
    pkg.managers.apt.is_available || return 0
    local rid pkgs=""
    for rid in $(pkg.recipes_by_action "upgrade:apt"); do
        local p=$(pkg.recipe_packages "$rid" "apt")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    sudo apt-get install --only-upgrade -y ${=pkgs}
}

pkg.managers.apt.setup_repos() {
    pkg.managers.apt.is_available || return 0
    local changed=0 key val key_url keyring_name keyring_path repo_key repo_line pkg_name
    
    local codename=$(lsb_release -cs 2>/dev/null || echo stable)
    local arch=$(dpkg --print-architecture 2>/dev/null || echo amd64)
    local distro=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo debian)

    typeset -A seen_keys
    for key in ${(k)pkg_recipes}; do
        [[ "$key" == *":apt_key" ]] || continue
        val="${pkg_recipes[$key]}"
        [[ -n "${seen_keys[$val]}" ]] && continue
        seen_keys[$val]=1

        key_url="${val%%|*}" keyring_name="${val#*|}"
        keyring_path="/etc/apt/keyrings/$keyring_name"
        
        key_url="${key_url//%CODENAME%/$codename}"
        key_url="${key_url//%ARCH%/$arch}"
        key_url="${key_url//%DISTRO%/$distro}"
        key_url="${key_url//%KEYRING%/$keyring_path}"

        sudo install -dm 755 /etc/apt/keyrings 2>/dev/null
        if [[ ! -f "$keyring_path" ]]; then
            echo "   Adding GPG key: $keyring_name"
            sudo curl -fsSL "$key_url" -o "$keyring_path" 2>/dev/null && { sudo chmod a+r "$keyring_path"; changed=1; }
        fi
    done

    typeset -A seen_repos
    for repo_key in ${(k)pkg_recipes}; do
        [[ "$repo_key" == *":apt_repo" ]] || continue
        val="${pkg_recipes[$repo_key]}"
        [[ -n "${seen_repos[$val]}" ]] && continue
        seen_repos[$val]=1
        pkg_name="${repo_key%:apt_repo}"
        keyring_name="${val%%|*}" repo_line="${val#*|}"
        keyring_path="/etc/apt/keyrings/$keyring_name"

        repo_line="${repo_line//%CODENAME%/$codename}"
        repo_line="${repo_line//%ARCH%/$arch}"
        repo_line="${repo_line//%DISTRO%/$distro}"
        repo_line="${repo_line//%KEYRING%/$keyring_path}"

        local list_file="/etc/apt/sources.list.d/dotfiles-${pkg_name}.list"
        if [[ ! -f "$list_file" ]] || [[ "$(< $list_file)" != "$repo_line" ]]; then
            echo "   Adding apt repo: $pkg_name"
            echo "$repo_line" | sudo tee "$list_file" >/dev/null && changed=1
        fi
    done
    [[ $changed -eq 1 ]] && sudo apt-get update -qq
}
