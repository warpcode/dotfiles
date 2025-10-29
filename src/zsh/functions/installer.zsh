# installer.zsh - Cross-platform package installer for dotfiles
#
# This module provides a system for registering and installing packages across different package managers.
# Apps register their package dependencies using _installer_package, and packages are
# automatically collected. Use _installer_install to install all collected packages.
#
# Priority order for package installation:
# 1. Flatpak (if flatpak mapping exists and flatpak is installed) - exclusive, no fallback
# 2. Snap (if snap mapping exists and snap is installed) - exclusive, no fallback
# 3. OS packages or defaults (only if no flatpak/snap mappings exist)
#
# Usage Examples:
#   _installer_package "default" tmux              # tmux on all OSes
#   _installer_package "debian" tmux tmux-tiny     # tmux-tiny on Debian
#   _installer_package "flatpak" discord com.discordapp.Discord  # Discord via Flatpak
#   _installer_package "snap" discord              # Discord via Snap
#   _installer_install                             # Install collected packages
#
# Supported package managers: macos (brew), debian (apt), fedora (dnf), arch (pacman), flatpak, snap
# Moved and refactored from install-deps.sh

# Global app mappings (set by apps at load time)
# Format: _installer_app_mappings[app:os]=package
declare -A _installer_app_mappings

# Verbose mode (set to 1 to enable logging)
typeset -i _installer_verbose=0

# Detect OS and return a string identifier
# Examines $OSTYPE and /etc/os-release to determine the operating system,
# returning one of: macos, debian, fedora, arch, unsupported, or unknown.
_installer_detect_os() {
    case $OSTYPE in
        darwin*) echo macos ;;
        linux*)
            [ -f /etc/os-release ] || { echo unknown; return; }
            . /etc/os-release
            case $ID in
                ubuntu|debian) echo debian ;;
                fedora|arch) echo $ID ;;
                *) echo unsupported ;;
            esac
            ;;
        *) echo unknown ;;
    esac
}

# Get the list of packages for a specific OS
# Dynamically builds and returns a space-separated string of packages
# for the given OS, preferring OS-specific mappings over defaults.
_installer_get_packages_for_os() {
    local os=$1
    local -A app_pkgs
    for key in ${(k)_installer_app_mappings}; do
        local app=${key%%:*}
        local map_os=${key#*:}
        if [[ $map_os == $os || $map_os == default ]]; then
            local pkg=${_installer_app_mappings[$key]}
            # Prefer OS-specific over default
            if [[ -z ${app_pkgs[$app]} || $map_os == $os ]]; then
                app_pkgs[$app]=$pkg
            fi
        fi
    done
    local packages=""
    for pkg in ${(v)app_pkgs}; do
        packages+=" $pkg"
    done
    echo "${packages# }"
}

# Function to register a package mapping for an app
# Registers a package dependency for a specific OS or as a default.
# Usage: _installer_package "debian" tmux
#        _installer_package "default" tmux
_installer_package() {
    # Input validation
    if [[ $# -lt 2 ]]; then
        echo "Usage: _installer_package <os> <app> [package]" >&2
        return 1
    fi

    local os=$1
    local app=$2
    local pkg=${3:-$app}

    # Validate package manager (basic check)
    if [[ ! $os =~ ^(default|macos|debian|fedora|arch|flatpak|snap)$ ]]; then
        echo "Warning: Unknown package manager '$os' specified for app '$app'" >&2
    fi

    # Set the mapping for this app:os
    _installer_app_mappings[$app:$os]=$pkg

    [[ $_installer_verbose -eq 1 ]] && echo "Registered package '$pkg' for $app on $os"
}



# Install packages using priority-based package manager selection
# For each app, checks in order: flatpak, snap, then OS-specific/default packages
_installer_install() {
    local os=$(_installer_detect_os)
    echo "Detected OS: $os"

    # Arrays to hold packages for each package manager
    local flatpak_packages=()
    local snap_packages=()
    local os_packages=()

    # Get unique app names
    local -A apps
    for key in ${(k)_installer_app_mappings}; do
        local app=${key%%:*}
        apps[$app]=1
    done

    # Process each app exactly once according to priority
    for app in ${(k)apps}; do
        # Check for flatpak mapping first
        if (( $+commands[flatpak] )) && [[ -n "${_installer_app_mappings[${app}:flatpak]}" ]]; then
            echo "HERE"
            flatpak_packages+=(${_installer_app_mappings[${app}:flatpak]})
            (( _installer_verbose == 1 )) && echo "Assigned $app to flatpak"
        # Check for snap mapping second
        elif (( $+commands[snap] )) && [[ -n ${_installer_app_mappings[${app}:snap]} ]]; then
            snap_packages+=(${_installer_app_mappings[${app}:snap]})
            (( _installer_verbose == 1 )) && echo "Assigned $app to snap"
        # Check for OS-specific or default mapping last
        else
            local pkg=""
            # Prefer OS-specific over default
            if [[ -n ${_installer_app_mappings[${app}:${os}]} ]]; then
                pkg=${_installer_app_mappings[${app}:${os}]}
                [[ $_installer_verbose -eq 1 ]] && echo "Assigned $app to $os"
            elif [[ -n ${_installer_app_mappings[${app}:default]} ]]; then
                pkg=${_installer_app_mappings[${app}:default]}
                [[ $_installer_verbose -eq 1 ]] && echo "Assigned $app to default"
            fi
            # Add package if found
            if [[ -n $pkg ]]; then
                os_packages+=($pkg)
            fi
        fi
    done

    # Install packages for each package manager
    if [ ${#flatpak_packages[@]} -gt 0 ]; then
        echo "Installing flatpak packages: ${flatpak_packages[*]}"
        flatpak install -y "${flatpak_packages[@]}"
    fi

    if [ ${#snap_packages[@]} -gt 0 ]; then
        echo "Installing snap packages: ${snap_packages[*]}"
        snap install "${snap_packages[@]}"
    fi

    if [ ${#os_packages[@]} -gt 0 ]; then
        echo "Installing OS packages: ${os_packages[*]}"
        case $os in
            macos)
                if ! (( $+commands[brew] )); then
                    echo "Homebrew not found. Please install Homebrew first." >&2
                    return 1
                fi

                brew install "${os_packages[@]}"
                ;;
            debian)
                sudo apt update && sudo apt install -y "${os_packages[@]}"
                ;;
            fedora)
                sudo dnf install -y "${os_packages[@]}"
                ;;
            arch)
                sudo pacman -Syu --noconfirm "${os_packages[@]}"
                ;;
            *)
                echo "Unsupported OS: $os" >&2
                return 1
                ;;
        esac
    fi

    # Check if no packages were assigned
    if [ ${#flatpak_packages[@]} -eq 0 ] && [ ${#snap_packages[@]} -eq 0 ] && [ ${#os_packages[@]} -eq 0 ]; then
        echo "No packages to install"
        return 0
    fi
}



