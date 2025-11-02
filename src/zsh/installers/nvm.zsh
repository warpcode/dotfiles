#!/usr/bin/env zsh
# nvm.zsh - Node Version Manager installation
#
# Registers post-install hook to ensure nvm is installed

# NVM version to install
NVM_INSTALL_VERSION="0.40.2"

# Function to ensure nvm is installed
_installer_post_nvm() {
    # Check current installation
    local current_version=""
    if which nvm &>/dev/null; then
        current_version=$(nvm --version 2>/dev/null)
    fi

    # Get target version using comparison function
    local target_version=$(_gh_compare_versions "nvm-sh/nvm" "$NVM_INSTALL_VERSION" "$current_version")
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to resolve nvm version" >&2
        return 1
    fi

    # If versions match, skip
    if [[ "$target_version" == "$current_version" ]]; then
        echo "🔄 nvm is already installed ($current_version)"
        return 0
    fi

    # Install/update
    if [[ -n "$current_version" ]]; then
        echo "📦 nvm version mismatch (installed: $current_version, target: $target_version). Installing..."
    else
        echo "📦 Installing nvm $target_version..."
    fi

    # Install nvm using the official install script
    local install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v${target_version#v}/install.sh"
    if env PROFILE=/dev/null bash -c "curl --fail -o- '$install_url' | bash"; then
        echo "✅ nvm $target_version installed successfully"
        # Note: Shell environment will be updated on next session via apps/nvm.zsh
    else
        echo "❌ Failed to install nvm" >&2
        return 1
    fi
}

# Register post-install hook
_events_add_hook "installer_post_install" "_installer_post_nvm"
