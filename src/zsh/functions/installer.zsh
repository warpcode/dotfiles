# installer.zsh - Cross-platform package installer for dotfiles
#
# This module provides a system for registering and installing packages across different OSes.
# Apps register their package dependencies using _installer_package, and packages are
# automatically collected. Use _installer_install_packages to install all collected packages.
#
# Usage Examples:
#   _installer_package "default" tmux          # tmux on all OSes
#   _installer_package "debian" tmux tmux-tiny # tmux-tiny on Debian
#   _installer_install_packages                # Install collected packages
#
# Supported OSes: macos, debian, fedora, arch
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

    # Validate OS (basic check)
    if [[ ! $os =~ ^(default|macos|debian|fedora|arch)$ ]]; then
        echo "Warning: Unknown OS '$os' specified for app '$app'" >&2
    fi

    # Set the mapping for this app:os
    _installer_app_mappings[$app:$os]=$pkg

    [[ $_installer_verbose -eq 1 ]] && echo "Registered package '$pkg' for $app on $os"
}



# Install packages for the detected OS
# Detects the OS and installs all packages for that OS
# using the appropriate package manager (brew, apt, dnf, pacman).
_installer_install() {
    local os=$(_installer_detect_os)
    echo "Detected OS: $os"

    local IFS=' '
    local packages=($(_installer_get_packages_for_os $os))

    # Check if any packages were collected for this OS
    if [ ${#packages[@]} -eq 0 ]; then
        echo "No packages collected for $os"
        return 0
    fi

    [[ $_installer_verbose -eq 1 ]] && echo "Installing packages for $os: ${packages[*]}"

    # Install based on OS (commented out for now, just print packages)
    case $os in
        macos)
            # if ! (( $+commands[brew] )); then
            #     echo "Homebrew not found. Please install Homebrew first." >&2
            #     return 1
            # fi
            echo "Would install on macOS with Homebrew: ${packages[*]}"
            # brew install "${packages[@]}"
            ;;
        debian)
            sudo apt update && sudo apt install -y "${packages[@]}"
            ;;
        fedora)
            echo "Would install on Fedora with dnf: ${packages[*]}"
            # sudo dnf install -y "${packages[@]}"
            ;;
        arch)
            echo "Would install on Arch with pacman: ${packages[*]}"
            # sudo pacman -Syu --noconfirm "${packages[@]}"
            ;;
        *)
            echo "Unsupported OS: $os" >&2
            return 1
            ;;
    esac
}



