# installer.zsh - Cross-platform package installer for dotfiles
#
# This module provides a system for registering and installing packages across different package managers
# and direct GitHub releases. Apps register their package dependencies using _installer_package, and packages are
# automatically collected. Use _installer_install to install all collected packages, or
# _installer_get_packages_for_os to retrieve packages for a specific manager.
#
# Package manager priority (checked in this order for each app):
# 1. Flatpak (if available and mapping exists)
# 2. Snap (if available and mapping exists)
# 3. GitHub releases (if mapping exists)
# 4. OS-specific packages or defaults
#
# Installation order (after priority selection):
# 1. OS packages (native system packages)
# 2. Flatpak packages
# 3. Snap packages
# 4. GitHub releases
#
# Usage Examples:
#   _installer_package "default" tmux              # tmux on all OSes
#   _installer_package "debian" tmux tmux-tiny     # tmux-tiny on Debian
#   _installer_package "flatpak" discord com.discordapp.Discord  # Discord via Flatpak
#   _installer_package "snap" discord              # Discord via Snap
#   _installer_package "github" fzf "junegunn/fzf@v0.66.1"  # GitHub release
#   _installer_install                             # Install collected packages
#   _installer_get_packages_for_os flatpak         # Get flatpak packages
#
# Supported package managers: macos (brew), debian (apt), fedora (dnf), arch (pacman), flatpak, snap, github
# GitHub releases support .tar.gz archives with automatic OS/arch detection and executable symlinking
# Moved and refactored from install-deps.sh

# Global app mappings (set by apps at load time)
# Format: _installer_app_mappings[app:os]=package
declare -A _installer_app_mappings

# Verbose mode (set to 1 to enable logging)
typeset -i _installer_verbose=0

# Installation directory for GitHub releases (can be overridden by INSTALLER_OPT_DIR env var)
: ${INSTALLER_OPT_DIR:="$HOME/.local/opt"}

# Detect OS and return a string identifier
# Examines $OSTYPE and /etc/os-release to determine the operating system,
# returning one of: macos, debian, fedora, arch, unsupported, or unknown.
# @return string OS identifier
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

# Detect architecture and return a string identifier
# Uses uname -m to determine the architecture,
# returning one of: x86_64, aarch64, or the raw uname output.
# @return string Architecture identifier
_installer_detect_arch() {
    case $(uname -m) in
        x86_64|amd64) echo x86_64 ;;
        aarch64|arm64) echo aarch64 ;;
        *) uname -m ;;
    esac
}

# Get the list of packages for a specific package manager or OS
# Dynamically builds and returns a space-separated string of packages
# for the given manager, following the same priority logic as _installer_install.
# @param manager The package manager or OS (e.g., flatpak, snap, debian)
# @return string Space-separated list of packages
_installer_get_packages_for_os() {
    local manager=$1
    local os=$(_installer_detect_os)

    # Determine available managers
    local available_flatpak=0
    (( $+commands[flatpak] )) && available_flatpak=1
    local available_snap=0
    (( $+commands[snap] )) && available_snap=1

    # Get unique app names
    local -A apps
    for key in ${(k)_installer_app_mappings}; do
        local app=${key%%:*}
        apps[$app]=1
    done

    # Collect packages for the manager
    local packages=()
    for app in ${(k)apps}; do
        local assigned_manager=""
        local pkg=""
        if (( available_flatpak )) && [[ -n ${_installer_app_mappings[${app}:flatpak]} ]]; then
            assigned_manager="flatpak"
            pkg=${_installer_app_mappings[${app}:flatpak]}
        elif (( available_snap )) && [[ -n ${_installer_app_mappings[${app}:snap]} ]]; then
            assigned_manager="snap"
            pkg=${_installer_app_mappings[${app}:snap]}
        elif [[ -n ${_installer_app_mappings[${app}:github]} ]]; then
            assigned_manager="github"
            pkg=${_installer_app_mappings[${app}:github]}
        else
            assigned_manager=$os
            if [[ -n ${_installer_app_mappings[${app}:${os}]} ]]; then
                pkg=${_installer_app_mappings[${app}:${os}]}
            elif [[ -n ${_installer_app_mappings[${app}:default]} ]]; then
                pkg=${_installer_app_mappings[${app}:default]}
            fi
        fi
        if [[ $assigned_manager == $manager ]]; then
            if [[ $manager == "github" ]]; then
                packages+=("$app:$pkg")
            else
                packages+=("$pkg")
            fi
        fi
    done

    # Join packages into space separated string
    local result=""
    for pkg in $packages; do
        result+=" $pkg"
    done
    echo "${result# }"
}

# Function to register a package mapping for an app
# Registers a package dependency for a specific OS or as a default.
# @param os The OS or package manager (e.g., debian, flatpak, default)
# @param app The app name
# @param package The package name (optional, defaults to app name)
# @return 0 on success, 1 on error
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
    if [[ ! $os =~ ^(default|macos|debian|fedora|arch|flatpak|snap|github)$ ]]; then
        echo "Warning: Unknown package manager '$os' specified for app '$app'" >&2
    fi

    # Set the mapping for this app:os
    _installer_app_mappings[$app:$os]=$pkg

    [[ $_installer_verbose -eq 1 ]] && echo "Registered package '$pkg' for $app on $os"
}

# Install packages using priority-based package manager selection
# For each app, checks availability in order: flatpak, snap, GitHub, then OS-specific/default packages.
# Installs in order: OS packages, flatpak, snap, GitHub releases
# Triggers 'installer_post_install' event after completion for additional setup.
# Uses _installer_get_packages_for_os to retrieve packages for each manager.
# @return 0 on success, 1 on error
_installer_install() {
    local os=$(_installer_detect_os)
    echo "Detected OS: $os"

    # Get packages for each package manager using the shared logic
    local flatpak_packages=($(_installer_get_packages_for_os flatpak))
    local snap_packages=($(_installer_get_packages_for_os snap))
    local github_packages=($(_installer_get_packages_for_os github))
    local os_packages=($(_installer_get_packages_for_os $os))

    # Install packages for each package manager (OS first, then alternatives)
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

    if [ ${#flatpak_packages[@]} -gt 0 ]; then
        echo "Installing flatpak packages: ${flatpak_packages[*]}"
        flatpak install -y "${flatpak_packages[@]}"
    fi

    if [ ${#snap_packages[@]} -gt 0 ]; then
        echo "Installing snap packages: ${snap_packages[*]}"
        snap install "${snap_packages[@]}"
    fi

    if [ ${#github_packages[@]} -gt 0 ]; then
        echo "Installing GitHub releases: ${github_packages[*]}"
        _installer_install_github "${github_packages[@]}"
    fi

    # Trigger post-install hooks
    _events_trigger "installer_post_install"

    # Check if no packages were assigned
    if [ ${#flatpak_packages[@]} -eq 0 ] && [ ${#snap_packages[@]} -eq 0 ] && [ ${#github_packages[@]} -eq 0 ] && [ ${#os_packages[@]} -eq 0 ]; then
        echo "No packages to install"
        return 0
    fi
}

# Install GitHub releases for the given app:repo@version items
# @param items Array of "app:repo@version" strings
# @return 0 on success, 1 on error
_installer_install_github() {
    for item in "$@"; do
        local app=${item%%:*}
        local pkg=${item#*:}
        local repo=${pkg%%@*}
        local version=${pkg#*@}
        _installer_github_download "$app" "$repo" "$version" || return 1
    done
}

# Download and install a GitHub release
# Resolves version, detects OS/arch, finds compatible .tar.gz asset,
# skips if already installed, then extracts and sets up the application
# @param app The app name (used for directory)
# @param repo The GitHub repo in owner/repo format
# @param version The version tag or "latest"
# @return 0 on success, 1 on error
_installer_github_download() {
    local app=$1
    local repo=$2
    local version=$3

    local os=$(_installer_detect_os)
    local arch=$(_installer_detect_arch)

    # Resolve latest version
    if [[ $version == "latest" ]]; then
        version=$(_gh_get_latest_release $repo)
        if [[ -z $version ]]; then
            echo "Failed to get latest release for $repo" >&2
            return 1
        fi
    fi

    local dir="$INSTALLER_OPT_DIR/$app"

    # Check current version
    if [[ -f "$dir/.version" ]]; then
        local current=$(<"$dir/.version")
        if [[ $current == $version ]]; then
            echo "$app is already at version $version"
            return 0
        fi
    fi

    echo "Installing $app version $version from $repo"

    # Build OS patterns
    local os_patterns=()
    if [[ $os =~ ^(debian|fedora|arch)$ ]]; then
        os_patterns=("linux")
    elif [[ $os == "macos" ]]; then
        os_patterns=("darwin" "macos")
    else
        os_patterns=("$os")
    fi

    # Build arch patterns
    local arch_patterns=()
    case $arch in
        x86_64) arch_patterns=("x86_64" "amd64" "x64") ;;
        aarch64) arch_patterns=("arm64" "aarch64") ;;
        *) arch_patterns=("$arch") ;;
    esac

    # Find compatible asset (only .tar.gz supported initially)
    local os_regex="($(IFS='|'; echo "${os_patterns[*]}"))"
    local arch_regex="($(IFS='|'; echo "${arch_patterns[*]}"))"
    local asset_url=$(
        _gh_get_asset_url $repo $version |
        grep -E "$os_regex" |
        grep -E "$arch_regex" |
        grep '\.tar\.gz$' |
        head -1
    )

    if [[ -z $asset_url ]]; then
        echo "No compatible .tar.gz asset found for $repo $version on $os $arch" >&2
        return 1
    fi

    _installer_extract_asset "$app" "$asset_url" "$version"
}

# Download and extract a GitHub release asset
# Downloads .tar.gz archive, extracts to $INSTALLER_OPT_DIR/app/,
# handles top-level directory flattening, creates bin/ symlinks to executables,
# and writes version file for tracking
# @param app The app name (used for directory)
# @param asset_url The URL of the asset to download
# @param version The version tag
# @return 0 on success, 1 on error
_installer_extract_asset() {
    local app=$1
    local asset_url=$2
    local version=$3

    local dir="$INSTALLER_OPT_DIR/$app"

    # Create directory
    mkdir -p "$dir"

    # Download and extract
    if curl -L "$asset_url" | tar -xzf - -C "$dir"; then
        # If extracted to a single subdirectory containing common Unix dirs, move contents up
        local subdirs=($(find "$dir" -mindepth 1 -maxdepth 1 -type d))
        if [[ ${#subdirs[@]} -eq 1 ]]; then
            local subdir=$subdirs[1]
            if [[ -d "$subdir/bin" || -d "$subdir/sbin" || -d "$subdir/usr" || -d "$subdir/lib" ]]; then
                setopt local_options dotglob
                mv "$subdir"/* "$dir"/ 2>/dev/null || true
                unsetopt dotglob
                rmdir "$subdir" 2>/dev/null || true
            fi
        fi

        # Ensure bin/ directory exists and contains symlinks to executables
        if [[ ! -d "$dir/bin" ]]; then
            mkdir -p "$dir/bin"
            # Find executable files and create symlinks in bin/
            for exe in $(find "$dir" -type f -executable); do
                local basename=$(basename "$exe")
                ln -sf "$exe" "$dir/bin/$basename"
            done
        fi
        echo "$version" > "$dir/.version"
        echo "Successfully installed $app version $version"
    else
        echo "Failed to download or extract $asset_url" >&2
        return 1
    fi
}

