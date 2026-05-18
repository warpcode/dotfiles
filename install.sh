#!/bin/bash

set -e

[ -z "$DOTFILES_INSTALL_DIR" ] && {
    if [[ -n "$DOTFILES" && -d "$DOTFILES" ]]; then DOTFILES_INSTALL_DIR="$DOTFILES"
    elif [ -d "$HOME/src/dotfiles" ]; then DOTFILES_INSTALL_DIR="$HOME/src/dotfiles"
    else DOTFILES_INSTALL_DIR="$HOME/.dotfiles"; fi
}

DOTFILES_SILENT="${DOTFILES_SILENT:-0}"
DOTFILES_SKIP_CHSHELL="${DOTFILES_SKIP_CHSHELL:-0}"
DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"

SUDO="sudo"; [ "$(id -u)" -eq 0 ] && SUDO=""

#;
# detect_os - Detects the operating system and returns a normalized identifier
detect_os() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*)
            [[ -n "$TERMUX_VERSION" && -d "$PREFIX" ]] && { echo "termux"; return; }
            [ -f /etc/os-release ] && . /etc/os-release
            case "${ID:-linux}" in
                ubuntu|debian) echo "debian" ;;
                fedora|arch) echo "$ID" ;;
                *) echo "linux" ;;
            esac ;;
        *) echo "unknown" ;;
    esac
}

#;
install() {
    local name="$1"
    shift

    command -v "$name" >/dev/null 2>&1 && echo "✅ $name is already installed" && return 0

    for spec in "$@"; do
        local mgr="${spec%%=*}"
        local pkg="${spec#*=}"

        command -v "${mgr%_cask}" >/dev/null 2>&1 || continue

        if { case "$mgr" in
            apt) dpkg -s $pkg ;;
            dnf) dnf list installed $pkg ;;
            pacman) pacman -Q $pkg ;;
            brew) brew list $pkg ;;
            brew_cask) brew list --cask $pkg ;;
            flatpak) flatpak info $pkg ;;
            snap) snap list "${pkg%% *}" ;;
            mise) mise where "$pkg" ;;
            npm) npm ls -g "${pkg%%@*}" ;;
        esac; } >/dev/null 2>&1; then
            echo "✅ $name is already installed via $mgr"
            return 0
        fi

        echo "📦 Installing $name via $mgr..."
        case "$mgr" in
            apt) $SUDO apt install -y $pkg ;;
            dnf) $SUDO dnf install -y $pkg ;;
            pacman) $SUDO pacman -S --noconfirm $pkg ;;
            brew) brew install $pkg ;;
            brew_cask) brew install --cask $pkg ;;
            flatpak) flatpak install -y $pkg ;;
            snap) $SUDO snap install $pkg ;;
            mise) mise use -g "$pkg" ;;
            npm) npm install -g "$pkg" ;;
        esac && return 0
    done

    echo "⚠️  $name: no installer available"
}

# ============================================================================
# OS-SPECIFIC SETUP
# ============================================================================

setup_debian() {
    echo "🐧 Setting up Debian/Ubuntu..."
    $SUDO apt update -qq

    local arch=$(dpkg --print-architecture)
    [ -f /etc/os-release ] && . /etc/os-release
    $SUDO install -m 0755 -d /etc/apt/keyrings

    [ -f /usr/share/keyrings/githubcli-archive-keyring.gpg ] || {
        echo "Configuring GitHub CLI repository..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        echo "deb [arch=$arch signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    }

    command -v mise >/dev/null || {
        echo "Configuring Mise repository..."
        curl -fsSL https://mise.jdx.dev/gpg-key.pub | $SUDO gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg 2>/dev/null || true
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | $SUDO tee /etc/apt/sources.list.d/mise.list > /dev/null
    }

    command -v docker >/dev/null || {
        echo "Configuring Docker repository..."
        curl -fsSL "https://download.docker.com/linux/$ID/gpg" | $SUDO tee /etc/apt/keyrings/docker.asc >/dev/null
        $SUDO chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    }

    $SUDO apt update -qq
}

setup_fedora() {
    echo "🎩 Setting up Fedora..."
    $SUDO dnf check-update -q || true
    command -v mise >/dev/null || $SUDO dnf copr enable -y jdxcode/mise
    $SUDO dnf update -y -q
}

setup_arch() {
    echo "🎱 Setting up Arch..."
    $SUDO pacman -Sy -q
}

setup_macos() {
    echo "🍎 Setting up macOS..."
    command -v brew >/dev/null || {
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    }
    brew update
}

setup_termux() {
    echo "📱 Setting up Termux..."
    pkg update -q
}

#;
# ensure_dotfiles - Ensures dotfiles are present in the install directory
ensure_dotfiles() {
    local repo_url="$1"

    if [[ -d "$DOTFILES_INSTALL_DIR" && -f "$DOTFILES_INSTALL_DIR/install.sh" ]]; then
        echo "Dotfiles already present at $DOTFILES_INSTALL_DIR"
        [[ -d "$DOTFILES_INSTALL_DIR/.git" ]] && (
            cd "$DOTFILES_INSTALL_DIR"
            echo "Initializing submodules..."
            command -v ssh >/dev/null && ssh -o ConnectTimeout=3 -o BatchMode=yes git@github.com 2>&1 | grep -q "successfully authenticated" &&
                echo "SSH connectivity to GitHub available." || {
                echo "SSH connectivity to GitHub unavailable. Forcing submodules to HTTPS..."
                git config --local url."https://github.com/".insteadOf "git@github.com:"
                git submodule sync --recursive >/dev/null 2>&1 || true
            }
            git submodule update --init --recursive --depth 1 --quiet 2>/dev/null || true
        )
        return 0
    fi

    [ -z "$repo_url" ] && { echo "Error: No repository URL provided and dotfiles not found" >&2; return 1; }

    echo "Cloning dotfiles to $DOTFILES_INSTALL_DIR..."
    mkdir -p "$(dirname "$DOTFILES_INSTALL_DIR")"
    git clone --depth 1 --recurse-submodules --shallow-submodules "$repo_url" "$DOTFILES_INSTALL_DIR"
}

#;
# get_shell - Retrieves the current user's default shell
get_shell() {
    local u=$(whoami)

    if [ "$os" = "macos" ]; then
        dscl . -read "/Users/$u" UserShell | awk '{print $2}'
        return
    fi

    getent passwd "$u" 2>/dev/null | cut -d: -f7 | grep . ||
        grep "^$u:" /etc/passwd 2>/dev/null | cut -d: -f7 | grep . ||
        echo "$SHELL"
}

#;
# set_zsh_default - Checks if zsh is the default shell and attempts to change it
set_zsh_default() {
    local zsh_path="$1" u=$(whoami)

    [[ "$(get_shell)" == *"/zsh"* ]] && echo "zsh is already the default shell." && return 0
    [[ "$DOTFILES_SKIP_CHSHELL" == "1" ]] && echo "Skipping shell change (DOTFILES_SKIP_CHSHELL=1)" && return 0

    echo "Changing default shell to zsh..."
    command -v chsh >/dev/null || { echo "⚠️  'chsh' not found. Set default shell to $zsh_path manually."; return 0; }

    $SUDO chsh -s "$zsh_path" "$u" && echo "Default shell changed to zsh successfully." || {
        echo "⚠️  Failed to change default shell automatically."
        echo "Please run: $SUDO chsh -s $zsh_path $u"
    }
}

# --- Main Execution ---

os=$(detect_os)
echo "Detected OS: $os"

# Run OS-specific setup
case "$os" in
    debian) setup_debian ;;
    fedora) setup_fedora ;;
    arch)   setup_arch ;;
    macos)  setup_macos ;;
    termux) setup_termux ;;
esac

# 1. Install core prerequisites
install "git" apt=git dnf=git pacman=git brew=git termux=git
install "zsh" apt=zsh dnf=zsh pacman=zsh brew=zsh termux=zsh
install "curl" apt=curl dnf=curl pacman=curl brew=curl termux=curl

# --- System Libraries & Dependencies ---
install "ca-certificates" apt=ca-certificates dnf=ca-certificates pacman=ca-certificates
install "gnupg" apt=gnupg2 dnf=gnupg2 brew=gnupg
install "libatomic" apt=libatomic1 dnf=libatomic pacman=gcc-libs
install "openssl" apt=openssl dnf=openssl brew=openssl
install "pkg-config" apt=pkg-config dnf=pkgconf-pkg-config brew=pkg-config
install "unzip" apt=unzip dnf=unzip brew=unzip
install "secret-tool" apt=libsecret-tools dnf=libsecret
install "bc" apt=bc dnf=bc pacman=bc brew=bc

# --- Package Managers & Core Integrations ---
install "flatpak" apt=flatpak dnf=flatpak pacman=flatpak
install "mise" apt=mise dnf=mise pacman=mise brew=mise
install "docker" brew=docker apt="docker-ce docker-compose-plugin" brew_cask=docker-desktop

# --- Runtimes ---
install "python3" mise=python@3.12
install "node" mise=node@latest
install "rust" mise=rust
install "go" mise=go
install "deno" mise=deno
install "php" apt=php-cli dnf=php-cli pacman=php brew=php

# --- System & CLI Tools ---
install "openssh" apt=openssh-client dnf=openssh-clients pacman=openssh
install "tmux" apt=tmux dnf=tmux pacman=tmux brew=tmux snap=tmux termux=tmux
install "screen" apt=screen dnf=screen pacman=screen brew=screen
install "rsync" apt=rsync dnf=rsync pacman=rsync brew=rsync
install "jq" apt=jq dnf=jq pacman=jq brew=jq termux=jq
install "yq" mise=yq
install "fzf" apt=fzf dnf=fzf pacman=fzf brew=fzf termux=fzf
install "bat" apt=bat dnf=bat pacman=bat brew=bat termux=bat
install "gomplate" mise=gomplate

# --- Development & VCS Tools ---
install "gh" mise=gh
install "lazygit" mise=lazygit@latest
install "neovim" mise=neovim@0.11.6
install "uv" mise=uv

# --- NPM Global Packages ---
# (npm is available after node is installed)
install "prettier" npm=prettier
install "eslint" npm=eslint
install "typescript-language-server" npm=typescript-language-server

# --- Apps & Productivity ---
install "discord" flatpak=com.discordapp.Discord brew_cask=discord
install "ffmpeg" apt=ffmpeg dnf=ffmpeg pacman=ffmpeg brew=ffmpeg
install "k8slens" snap="kontena-lens --classic" brew_cask=lens
install "keepassxc" flatpak=org.keepassxc.KeePassXC brew_cask=keepassxc

# --- AI Tools ---
install "ai_skills" npm=skills@latest
install "copilot-cli" npm=@github/copilot
install "gemini-cli" npm=@google/gemini-cli
install "ollama" mise=ollama
install "opencode" npm=opencode-ai@latest

# 2. Set Zsh as default shell
zsh_path=$(command -v zsh)
set_zsh_default "$zsh_path"

# 3. Clone repository
ensure_dotfiles "$DOTFILES_REPO_URL"

# 4. Set up installation directory
export DOTFILES="$DOTFILES_INSTALL_DIR"
cd "$DOTFILES"
command -v git >/dev/null && git config --global --add safe.directory "$DOTFILES"

# Source all functions, then execute recipe configure hooks
[ -f "src/zsh/init.zsh" ] && "$zsh_path" -c "source src/zsh/init.zsh && pkg.recipe.configure_all"

# 5. Hand off to internal Zsh configuration
echo -e "\nBootstrapping dotfiles..."
[ -f "src/zsh/init.zsh" ] && "$zsh_path" -c "source src/zsh/init.zsh && dotfiles.setup"

echo -e "\n✨ Bootstrap complete! Please restart your terminal or run 'exec zsh'."
