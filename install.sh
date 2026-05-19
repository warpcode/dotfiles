#!/bin/bash
#
# Bootstraps the dotfiles repository and dependencies.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

if [[ -z "${DOTFILES_INSTALL_DIR:-}" ]]; then
  if [[ -n "${DOTFILES:-}" && -d "${DOTFILES}" ]]; then
    readonly DOTFILES_INSTALL_DIR="${DOTFILES}"
  elif [[ -d "${HOME}/src/dotfiles" ]]; then
    readonly DOTFILES_INSTALL_DIR="${HOME}/src/dotfiles"
  else
    readonly DOTFILES_INSTALL_DIR="${HOME}/.dotfiles"
  fi
else
  readonly DOTFILES_INSTALL_DIR="${DOTFILES_INSTALL_DIR}"
fi

readonly DOTFILES_SILENT="${DOTFILES_SILENT:-0}"
readonly DOTFILES_SKIP_CHSHELL="${DOTFILES_SKIP_CHSHELL:-0}"
readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"

if [[ "$(id -u)" -eq 0 ]]; then
  readonly SUDO=""
else
  readonly SUDO="sudo"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Detects the operating system and returns a normalized identifier.
# Outputs:
#   Writes OS identifier to stdout (macos, debian, fedora, arch, termux, linux).
#######################################
detect_os() {
  case "${OSTYPE}" in
    darwin*) echo "macos" ;;
    linux*)
      if [[ -n "${TERMUX_VERSION:-}" && -d "${PREFIX:-}" ]]; then
        echo "termux"
        return 0
      fi
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
      fi
      case "${ID:-linux}" in
        ubuntu|debian) echo "debian" ;;
        fedora|arch) echo "${ID}" ;;
        *) echo "linux" ;;
      esac
      ;;
    *) echo "unknown" ;;
  esac
}

#######################################
# Installs a package using the appropriate package manager.
# Arguments:
#   $1 - Package name (for display).
#   $@ - List of manager=package mappings (e.g., apt=git brew=git).
# Outputs:
#   Status messages.
#######################################
install_pkg() {
  local name="$1"
  shift

  if command -v "${name}" >/dev/null 2>&1; then
    echo "✅ ${name} is already installed"
    return 0
  fi

  local spec mgr pkg
  for spec in "$@"; do
    mgr="${spec%%=*}"
    pkg="${spec#*=}"

    if ! command -v "${mgr%_cask}" >/dev/null 2>&1; then
      continue
    fi

    # Check if already installed
    local is_installed=0
    case "${mgr}" in
      apt) dpkg -s "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      dnf) dnf list installed "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      pacman) pacman -Q "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      brew) brew list "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      brew_cask) brew list --cask "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      flatpak) flatpak info "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      snap) snap list "${pkg%% *}" >/dev/null 2>&1 && is_installed=1 ;;
      mise) mise where "${pkg}" >/dev/null 2>&1 && is_installed=1 ;;
      npm) npm ls -g "${pkg%%@*}" >/dev/null 2>&1 && is_installed=1 ;;
    esac

    if [[ "${is_installed}" -eq 1 ]]; then
      echo "✅ ${name} is already installed via ${mgr}"
      return 0
    fi

    echo "📦 Installing ${name} via ${mgr}..."
    case "${mgr}" in
      apt) ${SUDO} apt install -y "${pkg}" ;;
      dnf) ${SUDO} dnf install -y "${pkg}" ;;
      pacman) ${SUDO} pacman -S --noconfirm "${pkg}" ;;
      brew) brew install "${pkg}" ;;
      brew_cask) brew install --cask "${pkg}" ;;
      flatpak) flatpak install -y "${pkg}" ;;
      snap) ${SUDO} snap install "${pkg}" ;;
      mise) mise use -g "${pkg}" ;;
      npm) npm install -g "${pkg}" ;;
    esac
    return 0
  done

  echo "⚠️  ${name}: no installer available"
}

#######################################
# Runs Debian/Ubuntu specific setup.
#######################################
setup_debian() {
  echo "🐧 Setting up Debian/Ubuntu..."
  ${SUDO} apt update -qq

  local arch
  arch="$(dpkg --print-architecture)"
  
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
  fi
  
  ${SUDO} install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]]; then
    echo "Configuring GitHub CLI repository..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | ${SUDO} dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=${arch} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | ${SUDO} tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  fi

  if ! command -v mise >/dev/null; then
    echo "Configuring Mise repository..."
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg 2>/dev/null || true
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | ${SUDO} tee /etc/apt/sources.list.d/mise.list > /dev/null
  fi

  if ! command -v docker >/dev/null; then
    echo "Configuring Docker repository..."
    curl -fsSL "https://download.docker.com/linux/${ID:-ubuntu}/gpg" | ${SUDO} tee /etc/apt/keyrings/docker.asc >/dev/null
    ${SUDO} chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID:-ubuntu} ${VERSION_CODENAME:-} stable" | ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  ${SUDO} apt update -qq
}

#######################################
# Runs Fedora specific setup.
#######################################
setup_fedora() {
  echo "🎩 Setting up Fedora..."
  ${SUDO} dnf check-update -q || true
  if ! command -v mise >/dev/null; then
    ${SUDO} dnf copr enable -y jdxcode/mise
  fi
  ${SUDO} dnf update -y -q
}

#######################################
# Runs Arch Linux specific setup.
#######################################
setup_arch() {
  echo "🎱 Setting up Arch..."
  ${SUDO} pacman -Sy -q
}

#######################################
# Runs macOS specific setup.
#######################################
setup_macos() {
  echo "🍎 Setting up macOS..."
  if ! command -v brew >/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update
}

#######################################
# Runs Termux specific setup.
#######################################
setup_termux() {
  echo "📱 Setting up Termux..."
  pkg update -q
}

#######################################
# Ensures dotfiles are cloned in the install directory.
# Arguments:
#   $1 - Repository URL.
# Returns:
#   0 on success, 1 on failure.
#######################################
ensure_dotfiles() {
  local repo_url="$1"

  if [[ -d "${DOTFILES_INSTALL_DIR}" && -f "${DOTFILES_INSTALL_DIR}/install.sh" ]]; then
    echo "Dotfiles already present at ${DOTFILES_INSTALL_DIR}"
    if [[ -d "${DOTFILES_INSTALL_DIR}/.git" ]]; then
      cd "${DOTFILES_INSTALL_DIR}" || return 1
      echo "Initializing submodules..."
      if command -v ssh >/dev/null && ssh -o ConnectTimeout=3 -o BatchMode=yes git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "SSH connectivity to GitHub available."
      else
        echo "SSH connectivity to GitHub unavailable. Forcing submodules to HTTPS..."
        git config --local url."https://github.com/".insteadOf "git@github.com:"
        git submodule sync --recursive >/dev/null 2>&1 || true
      fi
      git submodule update --init --recursive --depth 1 --quiet 2>/dev/null || true
    fi
    return 0
  fi

  if [[ -z "${repo_url}" ]]; then
    err "Error: No repository URL provided and dotfiles not found"
    return 1
  fi

  echo "Cloning dotfiles to ${DOTFILES_INSTALL_DIR}..."
  mkdir -p "$(dirname "${DOTFILES_INSTALL_DIR}")"
  git clone --depth 1 --recurse-submodules --shallow-submodules "${repo_url}" "${DOTFILES_INSTALL_DIR}"
}

#######################################
# Retrieves the current user's default shell.
# Globals:
#   OS_NAME
# Outputs:
#   Writes the absolute path of the default shell to stdout.
#######################################
get_shell() {
  local u
  u="$(whoami)"

  if [[ "${OS_NAME}" == "macos" ]]; then
    dscl . -read "/Users/${u}" UserShell | awk '{print $2}'
    return 0
  fi

  if getent passwd "${u}" 2>/dev/null | cut -d: -f7 | grep -q .; then
    getent passwd "${u}" 2>/dev/null | cut -d: -f7
  elif grep "^${u}:" /etc/passwd 2>/dev/null | cut -d: -f7 | grep -q .; then
    grep "^${u}:" /etc/passwd 2>/dev/null | cut -d: -f7
  else
    echo "${SHELL}"
  fi
}

#######################################
# Checks if zsh is the default shell and attempts to change it.
# Arguments:
#   $1 - Path to zsh.
#######################################
set_zsh_default() {
  local zsh_path="$1"
  local u
  u="$(whoami)"

  local current_shell
  current_shell="$(get_shell)"

  if [[ "${current_shell}" == *"/zsh"* ]]; then
    echo "zsh is already the default shell."
    return 0
  fi

  if [[ "${DOTFILES_SKIP_CHSHELL}" == "1" ]]; then
    echo "Skipping shell change (DOTFILES_SKIP_CHSHELL=1)"
    return 0
  fi

  echo "Changing default shell to zsh..."
  if ! command -v chsh >/dev/null; then
    echo "⚠️  'chsh' not found. Set default shell to ${zsh_path} manually."
    return 0
  fi

  if ${SUDO} chsh -s "${zsh_path}" "${u}"; then
    echo "Default shell changed to zsh successfully."
  else
    echo "⚠️  Failed to change default shell automatically."
    echo "Please run: ${SUDO} chsh -s ${zsh_path} ${u}"
  fi
}

# ---------------------------------------------------------------------------
# Profile Selection
# ---------------------------------------------------------------------------

#######################################
# Prompts the user to select a dotfiles profile.
# Uses df.tui if available; auto-selects in CI.
# Globals:
#   DOTFILES_INSTALL_DIR, CI
#######################################
select_profile() {
  local detected_profile
  detected_profile="$("${DOTFILES_INSTALL_DIR}/bin/df.fs" profile name)"

  local available_profiles=("default" "work" "phone")
  local user_profile=""

  if [[ -n "${CI:-}" ]]; then
    user_profile="${detected_profile}"
    echo "Running in CI. Automatically selecting profile: ${user_profile}"
  else
    user_profile="$("${DOTFILES_INSTALL_DIR}/bin/df.tui" select \
      -p "Select a profile" -d "${detected_profile}" "${available_profiles[@]}")"
  fi

  if [[ -z "${user_profile}" ]]; then
    err "Installation aborted. No profile selected."
    exit 1
  fi

  "${DOTFILES_INSTALL_DIR}/bin/df.fs" profile set "${user_profile}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Main execution function.
# Arguments:
#   $@ - All arguments passed to the script.
#######################################
main() {
  # Parse arguments
  local dotfiles_profile=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --profile)
        if [[ -n "${2:-}" ]]; then
          dotfiles_profile="$2"
          shift 2
        else
          err "Error: --profile requires an argument"
          exit 1
        fi
        ;;
      *) err "Unknown parameter: $1"; exit 1 ;;
    esac
  done

  # Make OS_NAME a global readonly variable for use in helper functions
  local os_val
  os_val="$(detect_os)"
  readonly OS_NAME="${os_val}"
  echo "Detected OS: ${OS_NAME}"

  case "${OS_NAME}" in
    debian) setup_debian ;;
    fedora) setup_fedora ;;
    arch)   setup_arch ;;
    macos)  setup_macos ;;
    termux) setup_termux ;;
  esac

  # 1. Install core prerequisites
  install_pkg "git" apt=git dnf=git pacman=git brew=git termux=git
  install_pkg "zsh" apt=zsh dnf=zsh pacman=zsh brew=zsh termux=zsh
  install_pkg "curl" apt=curl dnf=curl pacman=curl brew=curl termux=curl
  install_pkg "dialog" apt=dialog dnf=dialog pacman=dialog brew=dialog termux=dialog

  # 2. Set Zsh as default shell
  local zsh_path
  zsh_path="$(command -v zsh)" || true
  if [[ -n "${zsh_path}" ]]; then
    set_zsh_default "${zsh_path}"
  fi

  # 3. Clone repository
  ensure_dotfiles "${DOTFILES_REPO_URL}"

  # 4. Select profile (before remaining installs so they can be profile-aware)
  if [[ -n "${dotfiles_profile}" ]]; then
    echo "${dotfiles_profile}" > "${HOME}/.dotfiles_profile"
    echo "Profile set via argument to: ${dotfiles_profile}"
  else
    select_profile
  fi

  # 5. Set up installation directory
  export DOTFILES="${DOTFILES_INSTALL_DIR}"
  cd "${DOTFILES}" || exit 1
  if command -v git >/dev/null; then
    git config --global --add safe.directory "${DOTFILES}"
  fi

  # 6. Install system libraries & packages
  # --- System Libraries & Dependencies ---
  install_pkg "build-tools" apt=build-essential dnf="@development-tools" pacman=base-devel
  install_pkg "make" apt=make dnf=make pacman=make brew=make
  install_pkg "ca-certificates" apt=ca-certificates dnf=ca-certificates pacman=ca-certificates
  install_pkg "gnupg" apt=gnupg2 dnf=gnupg2 brew=gnupg
  install_pkg "libatomic" apt=libatomic1 dnf=libatomic pacman=gcc-libs
  install_pkg "openssl" apt=openssl dnf=openssl brew=openssl
  install_pkg "pkg-config" apt=pkg-config dnf=pkgconf-pkg-config brew=pkg-config
  install_pkg "unzip" apt=unzip dnf=unzip brew=unzip
  install_pkg "secret-tool" apt=libsecret-tools dnf=libsecret
  install_pkg "bc" apt=bc dnf=bc pacman=bc brew=bc

  # --- Package Managers & Core Integrations ---
  install_pkg "flatpak" apt=flatpak dnf=flatpak pacman=flatpak
  install_pkg "mise" apt=mise dnf=mise pacman=mise brew=mise
  install_pkg "docker" brew=docker apt="docker-ce docker-compose-plugin" brew_cask=docker-desktop

  # --- Runtimes ---
  install_pkg "python3" mise=python@3.12
  install_pkg "node" mise=node@latest
  install_pkg "rust" mise=rust
  install_pkg "go" mise=go
  install_pkg "deno" mise=deno
  install_pkg "php" apt=php-cli dnf=php-cli pacman=php brew=php

  # --- System & CLI Tools ---
  install_pkg "openssh" apt=openssh-client dnf=openssh-clients pacman=openssh
  install_pkg "tmux" apt=tmux dnf=tmux pacman=tmux brew=tmux snap=tmux termux=tmux
  install_pkg "screen" apt=screen dnf=screen pacman=screen brew=screen
  install_pkg "rsync" apt=rsync dnf=rsync pacman=rsync brew=rsync
  install_pkg "jq" mise=jq
  install_pkg "yq" mise=yq
  install_pkg "fzf" mise=fzf
  install_pkg "bat" mise=bat
  install_pkg "gomplate" mise=gomplate

  # --- Development & VCS Tools ---
  install_pkg "gh" mise=gh
  install_pkg "lazygit" mise=lazygit
  install_pkg "neovim" mise=neovim@0.11.6
  install_pkg "uv" mise=uv

  # --- NPM Global Packages ---
  # (npm is available after node is installed)
  install_pkg "prettier" npm=prettier
  install_pkg "eslint" npm=eslint
  install_pkg "typescript-language-server" npm=typescript-language-server

  # --- Apps & Productivity ---
  install_pkg "discord" flatpak=com.discordapp.Discord brew_cask=discord
  install_pkg "ffmpeg" apt=ffmpeg dnf=ffmpeg pacman=ffmpeg brew=ffmpeg
  install_pkg "k8slens" snap="kontena-lens --classic" brew_cask=lens
  install_pkg "keepassxc" flatpak=org.keepassxc.KeePassXC brew_cask=keepassxc

  # --- AI Tools ---
  install_pkg "ai_skills" npm=skills@latest
  install_pkg "copilot-cli" npm=@github/copilot
  install_pkg "gemini-cli" npm=@google/gemini-cli
  install_pkg "ollama" mise=ollama
  install_pkg "opencode" npm=opencode-ai@latest

  # 7. Source all functions, then execute recipe configure hooks
  if [[ -f "src/zsh/init.zsh" && -n "${zsh_path}" ]]; then
    "${zsh_path}" -c "source src/zsh/init.zsh && pkg.recipe.configure_all"
  fi

  # 8. Hand off to internal Zsh configuration
  echo -e "\nBootstrapping dotfiles..."
  if [[ -f "src/zsh/init.zsh" && -n "${zsh_path}" ]]; then
    "${zsh_path}" -c "source src/zsh/init.zsh && dotfiles.setup"
  fi

  echo -e "\n✨ Bootstrap complete! Please restart your terminal or run 'exec zsh'."
}

main "$@"
