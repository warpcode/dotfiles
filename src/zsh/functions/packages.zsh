# packages.zsh - Package installation utilities with app mappings and auto-detection
#
# This module provides functions for installing packages via various managers with app name mappings,
# versions, tags, automatic installer detection, and repository management. Supports apt, brew, brew-cask, dnf, pacman, pkg, flatpak, snap,
# and ZIP downloads to ~/.local/opt/.
#
# Mappings allow app names to differ per installer (e.g., vim:apt=vim, vim:dnf=vim-core).
# Auto-detection prioritizes managers by OS and availability.
#
# Usage:
#   _packages_register_app vim apt:vim=latest dnf:vim-core=8.2 :dep  # Register with package strings
#   _packages_install_app vim  # Install with auto-detection
#   _packages_install_apps vim neovim  # Install multiple apps
#   _packages_install_apps $(_packages_get_apps_by_tag dep) vim neovim  # Install deps first, then apps
#   _package_apt_repo kubectl https://packages.cloud.google.com/apt/doc/apt-key.gpg "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main"  # Register apt repo
#   _package_dnf_repo docker https://download.docker.com/linux/fedora/docker-ce.repo  # Register dnf repo
#   _packages_add_registered_repos  # Add all registered repos for current OS
#   _packages_add_key https://repo.example.com/key.gpg  # Add GPG key for apt
#   _packages_add_repo apt "deb [signed-by=/usr/share/keyrings/key.gpg] http://repo.example.com stable main"  # Add deb repo
#   _packages_add_repo dnf http://repo.example.com/repo.repo  # Add repo file
#   _packages_install_app vim  # Auto-detects and installs

# Global app-to-package mappings
# Format: _packages_app_mappings[app:manager]=package (may include version suffix)
declare -A _packages_app_mappings

# Global app tag mappings
# Format: _packages_app_tags[app]=tag
declare -A _packages_app_tags

# Global key mappings
# Format: _packages_key_mappings[repo_name:manager]=gpg_url|keyring_name
declare -A _packages_key_mappings

# Global repo mappings
# Format: _packages_repo_mappings[repo_name:manager]=config_string
declare -A _packages_repo_mappings

# Manager priorities per OS (space-separated strings)
declare -A _packages_os_priorities
_packages_os_priorities[macos]="brew-cask brew github"
_packages_os_priorities[linux]="flatpak snap apt dnf pacman github"
_packages_os_priorities[termux]="pkg"

# Register an app's package name for one or more managers and tag
# @param app The app name
# @param specs One or more manager:pkg1[=ver],pkg2,... specs, and optional :tag at end
# @return 0 on success
_packages_register_app() {
    local app=$1
    shift
    local tag="default"
    for spec in "$@"; do
        if [[ $spec == :* ]]; then
            tag=${spec#:}
            break
        fi
        # Parse manager:package1[=ver],package2,...
        local manager=${spec%%:*}
        local pkg_list=${spec#*:}
        # Lenient: skip invalid specs
        if [[ -z $manager || -z $pkg_list ]]; then
            continue
        fi
        # Split on comma and join with spaces
        local packages=()
        for p in ${(s:,:)pkg_list}; do
            packages+=("$p")
        done
        _packages_app_mappings[$app:$manager]="${packages[*]}"
    done
    _packages_app_tags[$app]=$tag
}

# Get apps by tag
# @param tag The tag to filter by
# @return space-separated sorted app names
_packages_get_apps_by_tag() {
    local tag=$1
    local apps=()
    for app in ${(k)_packages_app_tags}; do
        [[ ${_packages_app_tags[$app]} == $tag ]] && apps+=($app)
    done
    echo "${(o)apps[*]}"
}

# Register a repo config for a manager
# @param repo_name The repo name
# @param manager The package manager (apt, dnf)
# @param config_args Config arguments (gpg_url repo_line for apt; repo_url for dnf)
# @return 0 on success
_packages_register_repo() {
    local repo_name=$1
    local manager=$2
    shift 2
    case $manager in
        apt)
            if [[ $# -ne 1 ]]; then
                echo "❌ apt repo requires gpg_url|keyring_name|repo_line" >&2
                return 1
            fi
            _packages_repo_mappings["${repo_name}:apt"]="$1"
            ;;
        dnf)
            if [[ $# -ne 1 ]]; then
                echo "❌ dnf repo requires repo_url" >&2
                return 1
            fi
            _packages_repo_mappings["${repo_name}:dnf"]="$1"
            ;;
        dnf)
            if [[ $# -ne 1 ]]; then
                echo "❌ dnf repo requires repo_url" >&2
                return 1
            fi
            _packages_repo_mappings[${repo_name}:dnf]="$1"
            ;;
        *) echo "❌ Unsupported manager: $manager" >&2; return 1 ;;
    esac
}

# Install multiple apps
# @param apps App names to install
# @return 0 on success
_packages_install_apps() {
    echo "🚀 Installing apps: $@"
    for app in "$@"; do
        _packages_install_app $app
    done
}

# Install an app by name with auto-detection
# @param app The app name
# @return 0 on success
_packages_install_app() {
    local app=$1
    local os=$(_os_detect_os_family)
    local priorities
    if [[ $os == debian || $os == fedora || $os == arch ]]; then
        priorities=(${=_packages_os_priorities[linux]})
    else
        priorities=(${=_packages_os_priorities[$os]})
    fi
    for manager in $priorities; do
        local cmd=$manager
        [[ $manager == brew-cask ]] && cmd=brew
        if [[ $manager == github ]] || command -v $cmd >/dev/null 2>&1; then
            local package=${_packages_app_mappings[$app:$manager]}
            if [[ -n $package ]]; then
                echo "📦 Installing $app via $manager ($package)"
                local packages=(${(s: :)package})
                if _packages_install_with_manager $manager "${packages[@]}"; then
                    echo "    ✅ Installed $app successfully"
                    return 0
                else
                    return 1
                fi
            fi
        fi
    done
    echo "⚠️ Skipping $app (no installer found on $os)" >&2
    return 0
}

# Install packages with a specific manager
# @param manager The package manager
# @param packages Package names (may include version suffixes)
# @return 0 on success
_packages_install_with_manager() {
    local manager=$1
    shift
    case $manager in
        apt) sudo apt -o APT::Cmd::Disable-Script-Warning=true install -y -qq "$@" >/dev/null ;;
        brew) brew install -q "$@" >/dev/null ;;
        brew-cask) brew install --cask -q "$@" >/dev/null ;;
        dnf) sudo dnf install -y -q "$@" >/dev/null ;;
        pacman) sudo pacman -S --noconfirm -q "$@" >/dev/null ;;
        pkg) pkg install -y -q "$@" >/dev/null ;;
        flatpak) flatpak install -y -q "$@" >/dev/null ;;
        snap) snap install --quiet "$@" >/dev/null ;;
        github) _packages_install_from_github "$@" ;;
        *) echo "❌ Unknown manager: $manager" >&2; return 1 ;;
    esac
}

# Add a GPG key for apt repositories
# @param key_url The URL of the GPG key to add
# @param output_file The full path to save the dearmored key
# @return 0 on success
_packages_add_key() {
    local key_url=$1
    local output_file=$2
    if [[ $key_url == *.gpg || $key_url == *.asc ]]; then
        curl -fsSL "$key_url" | sudo gpg --dearmor -o "$output_file"
    else
        curl -fsSL "$key_url" | sudo tee "$output_file" > /dev/null
    fi
}

# Add a repository for a package manager
# @param manager The package manager
# @param repo The repository to add (format varies by manager)
#   - apt: PPA name (e.g., ppa:user/repo) or deb line (e.g., "deb http://repo.example.com stable main"). For deb822 (.sources), use manual addition.
#   - dnf: URL to .repo file (e.g., http://repo.example.com/repo.repo). Keys are handled if specified in the .repo file.
#   - brew/brew-cask: Tap name (e.g., user/repo)
#   - flatpak: Remote name and URL (e.g., "myremote http://repo.example.com")
# Note: For apt non-PPA repos, add keys with _packages_add_key before adding the repo.
# @return 0 on success
_packages_add_repo() {
    local manager=$1
    local repo=$2
    case $manager in
        apt) sudo add-apt-repository -y "$repo" ;;
        dnf) sudo dnf config-manager --add-repo "$repo" ;;
        pacman) echo "❌ Adding repos for pacman not supported automatically" >&2; return 1 ;;
        brew) brew tap "$repo" ;;
        brew-cask) brew tap "$repo" ;;
        flatpak) flatpak remote-add --if-not-exists "$repo" ;;
        snap) echo "Snap uses store, no repo add needed" >&2; return 1 ;;
        pkg) echo "❌ Adding repos for pkg not supported automatically" >&2; return 1 ;;
        *) echo "❌ Unknown manager: $manager" >&2; return 1 ;;
    esac
}

# Install from GitHub releases
# @param package app:repo@version
# @return 0 on success
_packages_install_from_github() {
    local package=$1
    local app=${package%%:*}
    local rest=${package#*:}
    local repo=${rest%%@*}
    local version=${rest#*@}
    # Assume _gh_install_release is available (from github.zsh)
    if command -v _gh_install_release >/dev/null 2>&1; then
        _gh_install_release "$app" "$repo" "$version"
    else
        echo "❌ _gh_install_release not available, cannot install from GitHub" >&2
        return 1
    fi
}

# Register an apt key
# @param repo_name The repo name
# @param gpg_url The GPG key URL
# @param keyring_name The keyring filename (e.g., docker-archive-keyring.gpg)
# @return 0 on success
_package_apt_key() {
    _packages_key_mappings["$1:apt"]="$2|$3"
}

# Register an apt repo
# @param repo_name The repo name
# @param repo_line The deb repo line
# @return 0 on success
_package_apt_repo() {
    _packages_repo_mappings["$1:apt"]="$2"
}

# Register a dnf repo
# @param repo_name The repo name
# @param repo_url The .repo file URL
# @return 0 on success
_package_dnf_repo() {
    _packages_register_repo "$1" dnf "$2"
}

# Add all registered keys for the current OS
# @return 0 on success
_packages_add_registered_keys() {
    local os=$(_os_detect_os_family)
    echo "🔑 Adding registered keys"
    for key in ${(k)_packages_key_mappings}; do
        local repo_name=${key%%:*}
        local manager=${key#*:}
        if [[ $manager == apt ]] && command -v apt >/dev/null 2>&1; then
            local config=${_packages_key_mappings[$key]}
            local gpg_url=${config%%|*}
            local keyring_name=${config#*|}
            local keyring_file="/usr/share/keyrings/$keyring_name"
            if [[ -f $keyring_file ]]; then
                echo "  ✅ $repo_name key already added"
            else
                echo "  🔑 Adding $repo_name key"
                _packages_add_key "$gpg_url" "$keyring_file"
                echo "    ✅ Added $repo_name key successfully"
            fi
        fi
    done
}

# Add all registered repos for the current OS
# @return 0 on success
_packages_add_registered_repos() {
    local os=$(_os_detect_os_family)
    echo "📦 Adding registered repos"
    for key in ${(k)_packages_repo_mappings}; do
        local repo_name=${key%%:*}
        local manager=${key#*:}
        if command -v $manager >/dev/null 2>&1; then
            local config=${_packages_repo_mappings[$key]}
            local already_exists=0
            if [[ $manager == apt ]]; then
                local repo_line=$config
                setopt localoptions noglob
                local evaluated_repo_line=$(eval echo "$repo_line")
                local keyring_file=$(echo "$repo_line" | sed 's/.*signed-by=\([^]]*\).*/\1/')
                if [[ -z $keyring_file || $keyring_file == $repo_line ]]; then
                    keyring_file="/usr/share/keyrings/${repo_name}.gpg"
                fi
                local repo_file="/etc/apt/sources.list.d/${repo_name}.list"
                if [[ -f $keyring_file ]] && [[ -f $repo_file ]] && grep -F -q "$evaluated_repo_line" "$repo_file"; then
                    already_exists=1
                fi
            elif [[ $manager == dnf ]]; then
                local repo_url=$config
                local repo_file="/etc/yum.repos.d/$(basename "$repo_url")"
                if [[ -f $repo_file ]]; then
                    already_exists=1
                fi
            fi
            if [[ $already_exists -eq 1 ]]; then
                echo "  ✅ $repo_name repo already configured for $manager"
            else
                echo "  📦 Adding $repo_name repo via $manager"
                if [[ $manager == apt ]]; then
                    echo "$evaluated_repo_line" | sudo tee "/etc/apt/sources.list.d/${repo_name}.list" > /dev/null
                elif [[ $manager == dnf ]]; then
                    _packages_add_repo dnf "$config"
                fi
                echo "    ✅ Added $repo_name repo successfully"
            fi
        fi
    done
}
