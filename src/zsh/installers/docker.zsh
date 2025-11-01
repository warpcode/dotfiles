# docker.zsh - Docker installation and configuration
#
# Registers Docker package and pre-install hooks for adding official repositories

# Register Docker packages
_installer_package "macos-cask" docker
_installer_package "debian" docker docker-ce docker-compose-plugin docker-model-plugin
_installer_package "fedora" docker docker-ce docker-compose-plugin docker-model-plugin
_installer_package "arch" docker docker docker-compose-plugin docker-model-plugin

# Function to add Docker's official repository (idempotent, follows official guides)
_installer_add_docker_repo() {
    local os=$1
    case $os in
        debian)
            # Source os-release to get ID
            . /etc/os-release
            # Use ID as distro for repo URL
            local distro=$ID
            # Define file paths and URLs
            local repo_file="/etc/apt/sources.list.d/docker.list"
            local keyring_file="/usr/share/keyrings/docker-archive-keyring.gpg"
            local gpg_url="https://download.docker.com/linux/$distro/gpg"
            # Check if Docker repo is already configured
            if [[ -f $repo_file ]] && [[ -f $keyring_file ]]; then
                echo "✅ Docker repository already configured for $distro"
                return 0
            fi
            echo "📦 Installing Docker repository for $distro"
            # Add Docker's official GPG key
            if ! curl --fail -fsSL "$gpg_url" | sudo gpg --dearmor -o "$keyring_file"; then
                echo "❌ Failed to download Docker GPG key from $gpg_url" >&2
                return 1
            fi
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring_file] https://download.docker.com/linux/$distro $VERSION_CODENAME stable" | sudo tee "$repo_file" > /dev/null
            ;;
        fedora)
            # Define file paths and URLs
            local repo_file="/etc/yum.repos.d/docker-ce.repo"
            local repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
            # Check if Docker repo is already configured (check repo file existence)
            if [[ -f $repo_file ]]; then
                echo "✅ Docker repository already configured for Fedora"
                return 0
            fi
            echo "📦 Installing Docker repository for Fedora"
            # Add Docker repository
            sudo dnf config-manager --add-repo "$repo_url"
            ;;
    esac
}

# Function to install docker-mcp directly to CLI plugins directory
_installer_post_docker_mcp() {
    # Only run on Linux
    if [[ $OSTYPE != *linux* ]]; then
        return 0
    fi

    local repo="docker/mcp-gateway"
    local target_dir="$HOME/.docker/cli-plugins/"
    local target="$target_dir/docker-mcp"

    # Check current version
    local current_version=""
    if [[ -f "$target" ]]; then
        current_version=$("$target" --version 2>/dev/null | sed 's/.*version //' | head -1)
    fi

    # Get target version using comparison function
    local target_version=$(_gh_compare_versions "$repo" "latest" "$current_version")
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to resolve docker-mcp version" >&2
        return 1
    fi

    # If versions match, skip
    if [[ "$target_version" == "$current_version" ]]; then
        echo "🔄 docker-mcp is already installed ($current_version)"
        return 0
    fi

    # Install/update
    if [[ -n "$current_version" ]]; then
        echo "📦 docker-mcp version mismatch (installed: $current_version, target: $target_version). Installing..."
    else
        echo "📦 Installing docker-mcp $target_version..."
    fi

    # Find asset URL (only Linux assets)
    local asset_url=$(
        _os_filter_by_arch "$(_gh_get_asset_url "$repo" "$target_version")" |
        grep "linux" |
        grep '\.tar\.gz$' |
        head -1
    )

    if [[ -z $asset_url ]]; then
        echo "❌ No compatible .tar.gz asset found for $repo $target_version on Linux" >&2
        return 1
    fi

    # Create directory
    mkdir -p "$target_dir"

    # Download and extract directly
    if curl --fail -L "$asset_url" | tar -xzf - -C "$target_dir"; then
        chmod +x "$target"
        echo "✅ Successfully installed docker-mcp $target_version"
    else
        echo "❌ Failed to download or extract $asset_url" >&2
        return 1
    fi
}

# Register pre-install hooks for repo setup
_events_add_hook "installer_post_deps" "_installer_add_docker_repo"
_events_add_hook "installer_post_install" "_installer_post_docker_mcp"
