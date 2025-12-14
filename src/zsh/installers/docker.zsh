# docker.zsh - Docker installation and configuration
#
# Registers Docker package and pre-install hooks for adding official repositories

# Docker MCP installation version
DOCKER_MCP_INSTALL_VERSION="latest"

# Register Docker packages
_packages_register_app docker \
    brew-cask:docker-desktop \
    apt:docker-ce,docker-compose-plugin,docker-model-plugin \
    dnf:docker-ce,docker-compose-plugin,docker-model-plugin \
    pacman:docker,docker-compose-plugin,docker-model-plugin

# Register Docker keys and repos
_package_apt_key docker https://download.docker.com/linux/debian/gpg docker-archive-keyring.gpg
_package_apt_repo docker "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
_package_dnf_repo docker https://download.docker.com/linux/fedora/docker-ce.repo


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
    local target_version=$(_gh_compare_versions "$repo" "$DOCKER_MCP_INSTALL_VERSION" "$current_version")
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
_events_add_hook "installer_post_install" "_installer_post_docker_mcp"
