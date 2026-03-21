#!/bin/bash

set -e

if [ -z "$DOTFILES_INSTALL_DIR" ]; then
    if [ -n "$DOTFILES" ] && [ -d "$DOTFILES" ]; then
        DOTFILES_INSTALL_DIR="$DOTFILES"
    elif [ -d "$HOME/src/dotfiles" ]; then
        DOTFILES_INSTALL_DIR="$HOME/src/dotfiles"
    else
        DOTFILES_INSTALL_DIR="$HOME/.dotfiles"
    fi
fi

DOTFILES_SILENT="${DOTFILES_SILENT:-0}"
DOTFILES_SKIP_CHSHELL="${DOTFILES_SKIP_CHSHELL:-0}"

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"
DOTFILES_REPOS_UPDATED=0

# Detect if we are running as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

#;
# detect_os - Detects the operating system and returns a normalized identifier
detect_os() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*)
            if [ -n "$TERMUX_VERSION" ] && [ -d "$PREFIX" ]; then
                echo "termux"
                return
            fi
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian) echo "debian";;
                    fedora) echo "fedora";;
                    arch) echo "arch";;
                    *) echo "linux";;
                esac
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

#;
# update_pkg_cache - Updates package cache if needed
update_pkg_cache() {
    [ "$DOTFILES_REPOS_UPDATED" -eq 1 ] && return 0

    echo "Updating package cache..."
    case "$1" in
        macos)    ;;
        debian)   $SUDO apt update -qq ;;
        fedora)   $SUDO dnf check-update -q || true ;;
        arch)     $SUDO pacman -Sy -q ;;
        termux)   pkg update -q ;;
    esac

    DOTFILES_REPOS_UPDATED=1
}

#;
# install_pkg - Installs a package via the OS-specific package manager
install_pkg() {
    local os="$1"
    local pkg="$2"

    if command -v "$pkg" >/dev/null 2>&1; then
        return 0
    fi

    update_pkg_cache "$os"

    echo "Installing $pkg on $os..."
    case "$os" in
        macos)    brew install -q "$pkg" ;;
        debian)   $SUDO apt install -y -qq "$pkg" ;;
        fedora)   $SUDO dnf install -y -q "$pkg" ;;
        arch)     $SUDO pacman -S --noconfirm --quiet "$pkg" ;;
        termux)   pkg install -y "$pkg" ;;
        *)        echo "Unsupported OS for auto-install: $os. Please install '$pkg' manually." >&2; return 1 ;;
    esac
}

#;
# ensure_dotfiles - Ensures dotfiles are present in the install directory
ensure_dotfiles() {
    local repo_url="$1"

    # If the directory exists and contains our signature file, we are good
    if [ -d "$DOTFILES_INSTALL_DIR" ] && [ -f "$DOTFILES_INSTALL_DIR/install.sh" ]; then
        echo "Dotfiles already present at $DOTFILES_INSTALL_DIR"

        if [ -d "$DOTFILES_INSTALL_DIR/.git" ]; then
            echo "Initializing submodules..."
            (cd "$DOTFILES_INSTALL_DIR" && git submodule update --init --recursive --depth 1 --quiet 2>/dev/null || true)
        fi
        return 0
    fi

    echo "Cloning dotfiles to $DOTFILES_INSTALL_DIR..."
    mkdir -p "$(dirname "$DOTFILES_INSTALL_DIR")"

    if [ -n "$repo_url" ]; then
        git clone --depth 1 --recurse-submodules --shallow-submodules "$repo_url" "$DOTFILES_INSTALL_DIR"
    else
        echo "Error: No repository URL provided and dotfiles not found" >&2
        return 1
    fi
}

#;
# get_shell - Retrieves the current user's default shell
get_shell() {
    if [ "$os" = "macos" ]; then
        dscl . -read "/Users/$(whoami)" UserShell | awk '{print $2}'
    else
        getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 ||
        grep "^$(whoami):" /etc/passwd 2>/dev/null | cut -d: -f7 ||
        echo "$SHELL"
    fi
}

#;
# set_zsh_default - Checks if zsh is the default shell and attempts to change it
set_zsh_default() {
    local zsh_path="$1"
    local current_shell=$(get_shell)

    if [[ "$current_shell" == *"/zsh"* ]]; then
        echo "zsh is already the default shell."
        return 0
    fi

    if [ "$DOTFILES_SKIP_CHSHELL" = "1" ]; then
        echo "Skipping shell change (DOTFILES_SKIP_CHSHELL=1)"
        return 0
    fi

    echo "Changing default shell to zsh..."
    if command -v chsh >/dev/null 2>&1; then
        if $SUDO chsh -s "$zsh_path" "$(whoami)"; then
            echo "Default shell changed to zsh successfully."
        else
            echo "⚠️  Failed to change default shell automatically."
            echo "Please run: $SUDO chsh -s $zsh_path $(whoami)"
        fi
    else
        echo "⚠️  'chsh' command not found. Please set your default shell to $zsh_path manually."
    fi
}

# --- Main Execution ---

os=$(detect_os)
echo "Detected OS: $os"

if [ "$os" = "macos" ] && ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" <<EOF
EOF
fi

# 1. Install core prerequisites
install_pkg "$os" git
install_pkg "$os" zsh
install_pkg "$os" curl

# Note: gomplate is installed via pkg.install bootstrap (direct download)
# Other tools (fzf, bat, mise, etc.) are installed via pkg.install post-bootstrap

# 2. Set Zsh as default shell
zsh_path=$(command -v zsh)
set_zsh_default "$zsh_path"

# 3. Clone repository
ensure_dotfiles "$DOTFILES_REPO_URL"

# 4. Hand off to internal Zsh configuration
echo "Bootstrapping dotfiles..."
cd "$DOTFILES_INSTALL_DIR"

# Source the internal init and run the dotfiles setup
$zsh_path -c "source src/zsh/init.zsh && dotfiles.setup"

echo
echo "✨ Bootstrap complete! Please restart your terminal or run 'exec zsh'."
