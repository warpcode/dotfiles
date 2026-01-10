# nvm.zsh - Node Version Manager recipe

_installer_post_nvm() {
    # NVM version to install
    local NVM_INSTALL_VERSION="0.40.2"
    
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
    echo "📦 Installing nvm $target_version..."

    # Install nvm using the official install script
    local install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v${target_version#v}/install.sh"
    if env PROFILE=/dev/null bash -c "curl --fail -o- '$install_url' | bash"; then
        echo "✅ nvm $target_version installed successfully"
    else
        echo "❌ Failed to install nvm" >&2
        return 1
    fi
}

typeset -A recipe=(
    [name]="nvm"
    [provides]="nvm"
    [depends]="curl"
    [post_install]="_installer_post_nvm"
    # nvm install is custom via post_install because it's a shell function, 
    # and we want to ensure it's loaded. 
    # We can use a dummy install_cmd if needed or just let post_install do it.
    [install_cmd]="true" 
)
