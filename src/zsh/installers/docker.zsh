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
                echo "Docker repository already configured for $distro"
                return 0
            fi
            echo "Installing Docker repository for $distro"
            # Add Docker's official GPG key
            curl -fsSL "$gpg_url" | sudo gpg --dearmor -o "$keyring_file"
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring_file] https://download.docker.com/linux/$distro $VERSION_CODENAME stable" | sudo tee "$repo_file" > /dev/null
            ;;
        fedora)
            # Define file paths and URLs
            local repo_file="/etc/yum.repos.d/docker-ce.repo"
            local repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
            # Check if Docker repo is already configured (check repo file existence)
            if [[ -f $repo_file ]]; then
                echo "Docker repository already configured for Fedora"
                return 0
            fi
            echo "Installing Docker repository for Fedora"
            # Add Docker repository
            sudo dnf config-manager --add-repo "$repo_url"
            ;;
    esac
}

# Register pre-install hooks for repo setup
_events_add_hook "installer_post_deps" "_installer_add_docker_repo"
_events_add_hook "installer_post_deps" "_installer_add_docker_repo"
