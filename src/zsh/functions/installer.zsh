# installer.zsh - Cross-platform package installer for dotfiles
#
# This module provides a system for registering and installing packages across different package managers
# and direct GitHub releases. Apps register their package dependencies using _installer_package, and packages are
# automatically collected. Use _installer_install to install all collected packages, or
# _installer_get_packages_for_pkg_mgr to retrieve packages for a specific manager.
#
# Package manager priority (checked in this order for each app):
# 1. Flatpak (if available and mapping exists)
# 2. Snap (if available and mapping exists)
# 3. GitHub releases (if mapping exists)
# 4. OS-specific packages or defaults
#
# Installation order (after priority selection):
# 1. Flatpak packages
# 2. Snap packages
# 3. OS packages (native system packages)
# 4. GitHub releases
#
# Usage Examples:
#   _installer_package "default" tmux              # tmux on all OSes
#   _installer_package "debian" tmux tmux-tiny     # tmux-tiny on Debian
#   _installer_package "flatpak" discord com.discordapp.Discord  # Discord via Flatpak
#   _installer_package "snap" discord              # Discord via Snap
#   _installer_package "github" fzf "junegunn/fzf@v0.66.1"  # GitHub release
#   _installer_install                             # Install collected packages
#   _installer_get_packages_for_pkg_mgr flatpak         # Get flatpak packages
#
# Supports apt, dnf, pacman, brew, flatpak, snap, github
# GitHub releases support .tar.gz archives with automatic OS/arch detection and executable symlinking

# Global app mappings (set by apps at load time)
# Format: _installer_app_mappings[app:os]=package
declare -A _installer_app_mappings

# Global dependency mappings (set by apps at load time)
# Format: _install_dependency_mappings[os]=packages
declare -A _install_dependency_mappings

# Verbose mode (set to 1 to enable logging)
typeset -i _installer_verbose=0

# Get packages for a manager.
# @param manager The package manager or OS
# @param app_filter Optional app name filter
# @return string packages
_installer_get_packages_for_pkg_mgr() {
    local manager=$1
    local app_filter=$2
    local current_os=$(_os_detect_os_family)

    # Special handling for dependencies
    if [[ $app_filter == "__deps__" ]]; then
        echo "${_install_dependency_mappings[$manager]%%[[:space:]]##}"
        return
    fi

    # Collect unique app names from all mappings
    local -A apps
    if [[ -n $app_filter ]]; then
        apps[$app_filter]=1
    else
        for key in ${(k)_installer_app_mappings}; do
            local app=${key%%:*}
            apps[$app]=1
        done
    fi

    # Get packages with conditional default fallback
    # Prioritize flatpak/snap for isolation before OS packages
    local packages=()
    for app in ${(k)apps}; do
        local pkg=""
        local has_flatpak_pkg=$(( $+commands[flatpak] && ${#_installer_app_mappings[${app}:flatpak]} > 0 ? 1 : 0 ))
        local has_snap_pkg=$(( $+commands[snap] && ${#_installer_app_mappings[${app}:snap]} > 0 ? 1 : 0 ))
        local has_os_pkg=$(( ${#_installer_app_mappings[${app}:${current_os}]} > 0 || (${current_os} == "macos" && ${#_installer_app_mappings[${app}:macos-brew]} > 0) ? 1 : 0 ))
        local has_default_pkg=$(( ${#_installer_app_mappings[${app}:default]} > 0 ? 1 : 0 ))
        local has_github_pkg=$(( ${#_installer_app_mappings[${app}:github]} > 0 ? 1 : 0 ))

        # Priority 1: Flatpak (containerized packages)
        if [[ $manager == "flatpak" ]] && [[ $has_flatpak_pkg -eq 1 ]]
        then
            pkg=${_installer_app_mappings[${app}:${manager}]}
        # Priority 2: macOS Cask (GUI apps)
        elif [[ $manager == "macos-cask" ]] && [[ -n ${_installer_app_mappings[${app}:${manager}]} ]]
        then
            pkg=${_installer_app_mappings[${app}:${manager}]}
        # Priority 3: Snap (if no flatpak available)
        elif [[ $manager == "snap" ]] && [[ $has_snap_pkg -eq 1 ]] && [[ $has_flatpak_pkg -eq 0 ]]
        then
            pkg=${_installer_app_mappings[${app}:snap]}
        # Priority 4: OS packages, defaults, or GitHub as last resort
        elif [[ $has_snap_pkg -eq 0 ]] && [[ $has_flatpak_pkg -eq 0 ]]
        then
            if [[ -n ${_installer_app_mappings[${app}:${manager}]} ]]
            then
                pkg=${_installer_app_mappings[${app}:${manager}]}
            elif [[ $has_default_pkg -eq 1 ]]
            then
                pkg=${_installer_app_mappings[${app}:default]}
            # Absolute last priority: GitHub releases
            elif [[ $manager == "github" ]] && [[ $has_github_pkg -eq 1 ]]
            then
                pkg="$app:${_installer_app_mappings[${app}:${manager}]}"
            fi
        fi
        if [[ -n $pkg ]]; then
            # Use robust splitting to handle potential edge cases (e.g., validate no colons in pkg if needed)
            packages+=("${(s: :)pkg}")
        fi
    done

    # Join packages into space separated string
    local result=""
    for pkg in "${packages[@]}"; do
        result+=" $pkg"
    done
    echo "${result# }"
}

# Function to register package mappings for an app
# Register package mappings for an app.
# @param package_manager The package manager
# @param app_name The app name
# @param packages Additional packages
# @return 0 on success
_installer_package() {
    # Input validation
    if [[ $# -lt 1 ]]; then
        echo "Usage: _installer_package <package_manager> [app_name] [package...]" >&2
        return 1
    fi

    local package_manager=$1
    local app_name=$2
    shift 2

    local app=$app_name
    local packages="$*"

    if [[ $# -eq 0 ]]; then
        packages=$app_name
    fi



    # Parse packages for @version:metadata (for future use)
    # For now, just store as is

    # Store space-separated packages
    _installer_app_mappings[$app:$package_manager]=$packages

    [[ $_installer_verbose -eq 1 ]] && echo "🔍 Registered packages '$packages' for $app on $package_manager"
}

# Get the package manager command for an OS
# Get package manager command for OS.
# @param os The OS identifier
# @return string cmd
_installer_get_pkg_mgr_for_os() {
    local os=$1
    case $os in
        debian) echo apt ;;
        fedora) echo dnf ;;
        arch) echo pacman ;;
        macos) echo brew ;;
        *) echo unknown ;;
    esac
}

# Install packages using a manager.
# @param pkg_mgr The package manager
# @param packages Array of packages
# @return 0 on success
_installer_install_packages() {
    local pkg_mgr=$1
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    # Check sudo availability for package managers that require it
    case $pkg_mgr in
        apt|dnf|pacman)
            if ! (( $+commands[sudo] )); then
                echo "❌ sudo not available, required for $pkg_mgr" >&2
                return 1
            fi
            ;;
    esac

    case $pkg_mgr in
        apt)
            if ! sudo apt update && sudo apt install -y "${packages[@]}"; then
                echo "❌ apt install failed" >&2
                return 1
            fi
            ;;
        dnf)
            if ! sudo dnf install -y "${packages[@]}"; then
                echo "❌ dnf install failed" >&2
                return 1
            fi
            ;;
        pacman)
            if ! sudo pacman -Syu --noconfirm "${packages[@]}"; then
                echo "❌ pacman install failed" >&2
                return 1
            fi
            ;;
        brew)
            if ! brew install "${packages[@]}"; then
                echo "❌ brew install failed" >&2
                return 1
            fi
            ;;
        brew-cask)
            if ! brew install --cask "${packages[@]}"; then
                echo "❌ brew cask install failed" >&2
                return 1
            fi
            ;;
        *)
            echo "❌ Unsupported package manager: $pkg_mgr" >&2
            return 1
            ;;
    esac
}

# Register prerequisite dependencies.
# @param package_manager The package manager
# @param packages The packages
# @return 0 on success
_installer_dependencies() {
    # Input validation
    if [[ $# -lt 1 ]]; then
        echo "Usage: _installer_dependencies <package_manager> [package...]" >&2
        return 1
    fi

    local package_manager=$1
    shift

    local packages="$*"



    # Parse packages for @version:metadata (for future use)
    # For now, just store as is

    # Store space-separated packages in the dependency mappings
    # Append to existing packages if already set
    if [[ -n ${_install_dependency_mappings[$package_manager]} ]]; then
        _install_dependency_mappings[$package_manager]="${_install_dependency_mappings[$package_manager]} $packages"
    else
        _install_dependency_mappings[$package_manager]=$packages
    fi

    [[ $_installer_verbose -eq 1 ]] && echo "🔍 Registered dependencies '$packages' for $package_manager"
}

# Install all collected packages with priority.
# @return 0 on success
_installer_install() {
    echo "🚀 Starting Installation"

    local os=$(_os_detect_os_family)
    echo "🔍 Detected OS: $os"

    # Get packages for each package manager using the shared logic
    local flatpak_packages=($(_installer_get_packages_for_pkg_mgr flatpak))
    local snap_packages=($(_installer_get_packages_for_pkg_mgr snap))
    local github_packages=($(_installer_get_packages_for_pkg_mgr github))
    local os_packages=()
    local brew_packages=()
    local cask_packages=()
    if [[ $os == "macos" ]]; then
        brew_packages=($(_installer_get_packages_for_pkg_mgr macos-brew))
        cask_packages=($(_installer_get_packages_for_pkg_mgr macos-cask))
    else
        os_packages=($(_installer_get_packages_for_pkg_mgr "$os"))
    fi

    # Trigger post-dependencies hook
    _events_trigger "installer_pre_deps" "$os"

    echo ""
    # Install prerequisite dependencies first
    local deps_packages=($(_installer_get_packages_for_pkg_mgr "$os" __deps__))
    if [ ${#deps_packages[@]} -gt 0 ]; then
        echo "📦 Installing prerequisite dependencies: ${deps_packages[*]}"
        if [[ $os == "macos" ]] && ! (( $+commands[brew] )); then
            echo "❌ Homebrew not found. Please install Homebrew first." >&2
            return 1
        fi
        _installer_install_packages "$(_installer_get_pkg_mgr_for_os "$os")" "${deps_packages[@]}"
    fi

    # Trigger post-dependencies hook
    _events_trigger "installer_post_deps" "$os"

    # Trigger pre-install hooks for OS-specific repo setup (after deps are installed)
    _events_trigger "installer_pre_install" "$os"

    echo ""
    # Install packages for each package manager (flatpak/snap first, then OS, then GitHub)
    if [ ${#flatpak_packages[@]} -gt 0 ]; then
        echo "📦 Installing flatpak packages: ${flatpak_packages[*]}"
        if ! flatpak install -y "${flatpak_packages[@]}"; then
            echo "❌ Flatpak install failed" >&2
            return 1
        fi
    fi

    if [ ${#snap_packages[@]} -gt 0 ]; then
        echo "📦 Installing snap packages: ${snap_packages[*]}"
        if ! snap install "${snap_packages[@]}"; then
            echo "❌ Snap install failed" >&2
            return 1
        fi
    fi

    if [[ $os == "macos" ]]; then
        if ! (( $+commands[brew] )); then
            echo "❌ Homebrew not found. Please install Homebrew first." >&2
            return 1
        fi

        if [ ${#brew_packages[@]} -gt 0 ]; then
            echo "📦 Installing Homebrew packages: ${brew_packages[*]}"
            _installer_install_packages brew "${brew_packages[@]}"
        fi

        if [ ${#cask_packages[@]} -gt 0 ]; then
            echo "📦 Installing Homebrew cask packages: ${cask_packages[*]}"
            _installer_install_packages brew-cask "${cask_packages[@]}"
        fi
    elif [ ${#os_packages[@]} -gt 0 ]; then
        echo "📦 Installing OS packages: ${os_packages[*]}"
        _installer_install_packages "$(_installer_get_pkg_mgr_for_os "$os")" "${os_packages[@]}"
    fi

    echo ""
    if [ ${#github_packages[@]} -gt 0 ]; then
        echo "📦 Installing GitHub releases: ${github_packages[*]}"
        if ! _installer_install_github "${github_packages[@]}"; then
            echo "❌ GitHub install failed" >&2
            return 1
        fi
    fi

    # Trigger post-install hooks
    _events_trigger "installer_post_install"

    # Check if no packages were assigned
    if [ ${#flatpak_packages[@]} -eq 0 ] && [ ${#snap_packages[@]} -eq 0 ] && [ ${#github_packages[@]} -eq 0 ] && [ ${#os_packages[@]} -eq 0 ]; then
        echo "ℹ️ No packages to install"
        return 0
    fi

    echo "✅ Installation Complete"
    echo "🎉 All packages have been successfully installed! Your dotfiles environment is ready to use."

    # Reload configuration to ensure PATH and latest config are applied
    reload
}

# Install GitHub releases.
# @param items Array of app:repo@version strings
# @return 0 on success
_installer_install_github() {
    for item in "$@"; do
        local app=${item%%:*}
        local pkg=${item#*:}
        local repo=${pkg%%@*}
        local version=${pkg#*@}
        _gh_install_release "$app" "$repo" "$version" || return 1
    done
}


