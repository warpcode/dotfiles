_packages_register_app git \
    apt:git \
    brew:git \
    dnf:git \
    pacman:git \
    cmd:git

# Function to set global git config
_installer_post_git_config() {
    echo "📦 Setting global git config..."
    git config --global include.path "~/.gitconfig_default"
    echo "✅ Global git config set successfully"
}

# Register post-install hook for git config
_events_add_hook "installer_post_install:git" "_installer_post_git_config"