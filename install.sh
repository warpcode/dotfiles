#!/bin/bash
#
# Bootstraps the dotfiles repository and dependencies using Chezmoi.

set -euo pipefail
trap 'printf "\n"; exit 130' INT TERM

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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
      local os_id="linux"
      if [[ -f /etc/os-release ]]; then
        os_id="$(grep -E '^ID=' /etc/os-release 2>/dev/null \
          | cut -d= -f2 \
          | tr -d '"' || echo "linux")"
      fi
      case "${os_id}" in
        ubuntu|debian) echo "debian" ;;
        fedora|arch) echo "${os_id}" ;;
        *) echo "linux" ;;
      esac
      ;;
    *) echo "unknown" ;;
  esac
}

#######################################
# Executes a command as root using sudo if necessary.
# Arguments:
#   $@ - The command to execute.
#######################################
run_as_root() {
  if [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DOTFILES_INSTALL_DIR="${DOTFILES_INSTALL_DIR:-${DOTFILES:-}}"
if [[ -z "${DOTFILES_INSTALL_DIR}" ]]; then
  DOTFILES_INSTALL_DIR="${HOME}/.dotfiles"
fi


readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"
readonly OS_NAME="$(detect_os)"

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"
DOTFILES_REPOS_UPDATED=0

err() {
  printf '[%s] ❌ %b\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >&2
}

info() {
  printf '💬 %b\n' "$1"
}

success() {
  printf '✅ %b\n' "$1"
}

warn() {
  printf '⚠️  %b\n' "$1" >&2
}

# ---------------------------------------------------------------------------
# OS Setup
# ---------------------------------------------------------------------------

#######################################
# Runs macOS specific setup.
#######################################
setup_macos() {
  info "Setting up macOS..."
  if ! command -v brew >/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update || true
}

# ---------------------------------------------------------------------------
# Prerequisites Setup
# ---------------------------------------------------------------------------

#######################################
# Ensures git, zsh, curl are installed on the system.
#######################################
ensure_bootstrap_packages() {
  # These overlap intentionally with chezmoi's 'system' group — we need
  # git, zsh, and curl available before chezmoi can run.
  info "Ensuring bootstrap prerequisites (git, zsh, curl) are installed..."
  case "${OS_NAME}" in
    debian)
      run_as_root apt update -qq
      run_as_root apt install -y -qq git zsh curl ca-certificates gnupg
      ;;
    fedora)
      run_as_root dnf install -y git zsh curl ca-certificates
      ;;
    arch)
      run_as_root pacman -Sy --noconfirm git zsh curl
      ;;
    macos)
      brew install git zsh curl || true
      ;;
    termux)
      pkg install -y git zsh curl
      ;;
  esac
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

  if [[ -d "${DOTFILES_INSTALL_DIR}" && \
        -f "${DOTFILES_INSTALL_DIR}/install.sh" ]]; then
    success "Dotfiles already present at ${DOTFILES_INSTALL_DIR}"
    return 0
  fi

  if [[ -z "${repo_url}" ]]; then
    err "Error: No repository URL provided and dotfiles not found"
    return 1
  fi

  info "Cloning dotfiles to ${DOTFILES_INSTALL_DIR}..."
  mkdir -p "$(dirname "${DOTFILES_INSTALL_DIR}")"
  git clone --depth 1 --recurse-submodules --shallow-submodules \
    "${repo_url}" "${DOTFILES_INSTALL_DIR}"
}

#######################################
# Main execution function.
# Arguments:
#   $@ - All arguments passed to the script.
#######################################
main() {
  local dotfiles_profile=""
  local git_name=""
  local git_email=""
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
      --git-name)
        if [[ -n "${2:-}" ]]; then
          git_name="$2"
          shift 2
        else
          err "Error: --git-name requires an argument"
          exit 1
        fi
        ;;
      --git-email)
        if [[ -n "${2:-}" ]]; then
          git_email="$2"
          shift 2
        else
          err "Error: --git-email requires an argument"
          exit 1
        fi
        ;;
      *) err "Unknown parameter: $1"; exit 1 ;;
    esac

  if [[ -n "${dotfiles_profile}" ]]; then
    success "Profile set via argument to: ${dotfiles_profile}"
  fi

  info "Detected OS: ${OS_NAME}"

  if [[ "${OS_NAME}" == "macos" ]]; then
    setup_macos
  fi

  # Ensure bootstrap packages (git, zsh, curl)
  ensure_bootstrap_packages

  # Refresh command hash after core installations
  hash -r 2>/dev/null || true

  # Clone repository
  ensure_dotfiles "${DOTFILES_REPO_URL}"

  # Set up installation directory
  export DOTFILES="${DOTFILES_INSTALL_DIR}"
  cd "${DOTFILES}" || exit 1
  if command -v git >/dev/null; then
    if ! git config --global --get-all safe.directory 2>/dev/null | grep -qxF "${DOTFILES}"; then
      git config --global --add safe.directory "${DOTFILES}"
    fi
  fi

  # Install/bootstrap chezmoi
  if ! command -v chezmoi >/dev/null && [ ! -f "${HOME}/.local/bin/chezmoi" ]; then
    info "Installing chezmoi..."
    mkdir -p "${HOME}/.local/bin"
    curl -fsLS https://chezmoi.io/get | sh -s -- -b "${HOME}/.local/bin"
  fi

  export PATH="${HOME}/.local/bin:${PATH}"

  # Apply dotfiles via chezmoi
  info "Applying dotfiles via Chezmoi..."
  # This will trigger:
  # - run_once_after_05-system.sh (install system pkgs)
  # - run_once_after_06-repositories.sh (setup 3rd party repos)
  # - run_once_after_07-integration.sh (install integration pkgs)
  # - run_once_after_08-install-packages.sh (install rest)
  # - run_once_after_10-set-zsh.sh (set default shell)
  local -a chezmoi_global_args=()
  # Build --override-data JSON for template variables
  # chezmoi --override-data accepts a JSON string as a global flag (before subcommand)
  local override_data="{}"
  if [[ -n "${dotfiles_profile}" || -n "${git_name}" || -n "${git_email}" ]]; then
    local profile_json="null"
    local git_name_json="null"
    local git_email_json="null"
    [[ -n "${dotfiles_profile}" ]] && profile_json="\"${dotfiles_profile}\""
    [[ -n "${git_name}" ]]        && git_name_json="\"${git_name}\""
    [[ -n "${git_email}" ]]       && git_email_json="\"${git_email}\""
    override_data="{\"profile\":${profile_json},\"git_name\":${git_name_json},\"git_email\":${git_email_json}}"
    chezmoi_global_args+=(--override-data "${override_data}")
  fi
  chezmoi "${chezmoi_global_args[@]}" init --apply --source "${DOTFILES}"

  success "Bootstrap complete! Please restart your terminal or run 'exec zsh'."
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
            (
                cd "$DOTFILES_INSTALL_DIR"

                # Check for SSH connectivity to GitHub
                if command -v ssh >/dev/null 2>&1 && ssh -o ConnectTimeout=3 -o BatchMode=yes git@github.com 2>&1 | grep -q "successfully authenticated"; then
                    echo "SSH connectivity to GitHub available."
                else
                    echo "SSH connectivity to GitHub unavailable. Forcing submodules to HTTPS..."
                    git config --local url."https://github.com/".insteadOf "git@github.com:"
                    git submodule sync --recursive >/dev/null 2>&1 || true
                fi

                git submodule update --init --recursive --depth 1 --quiet 2>/dev/null || true
            )
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

# 4. Run staged package installation
cd "$DOTFILES_INSTALL_DIR"
export DOTFILES="$DOTFILES_INSTALL_DIR"

# Mark directory as safe for git (fixes issue in GitHub Actions containers)
if command -v git >/dev/null 2>&1; then
    git config --global --add safe.directory "$DOTFILES"
fi

# Source all functions, run staged installation, then execute recipe configure hooks
zsh -c "source src/zsh/init.zsh && pkg.install_all && pkg.recipe.configure_all"

# 5. Hand off to internal Zsh configuration
echo ""
echo "Bootstrapping dotfiles..."

# Source the internal init and run the dotfiles setup
$zsh_path -c "source src/zsh/init.zsh && dotfiles.setup"

echo
echo "✨ Bootstrap complete! Please restart your terminal or run 'exec zsh'."
