#!/bin/bash
#
# Bootstraps the dotfiles repository and dependencies using Chezmoi.

set -euo pipefail
trap 'printf "\n"; exit 130' INT TERM

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

#######################################
# Detects the operating system and returns a normalised identifier.
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
readonly DOTFILES_INSTALL_DIR


readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"
readonly OS_NAME="$(detect_os)"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

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
# Ensures git, zsh, curl, jq are installed on the system.
#######################################
ensure_bootstrap_packages() {
  # These overlap intentionally with chezmoi's 'system' group — we need
  # git, zsh, curl, and jq available before chezmoi can run.
  info "Ensuring bootstrap prerequisites (git, zsh, curl, jq) are installed..."

  case "${OS_NAME}" in
    debian)
      run_as_root apt update -qq
      run_as_root apt install -y -qq git zsh curl jq ca-certificates gnupg
      ;;
    fedora)
      run_as_root dnf install -y git zsh curl jq ca-certificates
      ;;
    arch)
      run_as_root pacman -Sy --noconfirm git zsh curl jq
      ;;
    macos)
      setup_macos
      HOMEBREW_NO_INSTALL_UPGRADE=1 brew install git zsh curl jq || true
      ;;
    termux)
      pkg install -y git zsh curl jq
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
  local keepass_db=""
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
      --keepass-db)
        if [[ -n "${2:-}" ]]; then
          keepass_db="$2"
          shift 2
        else
          err "Error: --keepass-db requires an argument"
          exit 1
        fi
        ;;
      *) err "Unknown parameter: $1"; exit 1 ;;
    esac
  done

  if [[ -n "${dotfiles_profile}" ]]; then
    success "Profile set via argument to: ${dotfiles_profile}"
  fi

  info "Detected OS: ${OS_NAME}"

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
  
  # install chezmoi if not already installed
  if ! command -v chezmoi >/dev/null; then
    info "Installing chezmoi..."
    if [[ "${OS_NAME}" == "macos" ]]; then
      brew install chezmoi || true
    else
      mkdir -p "${HOME}/.local/bin"
      local chezmoi_install_script
      chezmoi_install_script="$(mktemp -t chezmoi-bootstrap-XXXXXX.sh)"
      if curl -fsSL https://chezmoi.io/get > "${chezmoi_install_script}"; then
        sh "${chezmoi_install_script}" -b "${HOME}/.local/bin"
        rm -f "${chezmoi_install_script}"
      else
        err "Failed to download chezmoi installer"
        rm -f "${chezmoi_install_script}"
        exit 1
      fi
    fi
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
  if [[ -n "${dotfiles_profile}" || -n "${git_name}" || -n "${git_email}" || -n "${keepass_db}" ]]; then
    local profile_json="null"
    local git_name_json="null"
    local git_email_json="null"
    local keepass_db_json="null"
    [[ -n "${dotfiles_profile}" ]] && profile_json="\"${dotfiles_profile}\""
    [[ -n "${git_name}" ]]        && git_name_json="\"${git_name}\""
    [[ -n "${git_email}" ]]       && git_email_json="\"${git_email}\""
    [[ -n "${keepass_db}" ]]      && keepass_db_json="\"${keepass_db}\""
    override_data="{\"profile\":${profile_json},\"git_name\":${git_name_json},\"git_email\":${git_email_json},\"keepass_db\":${keepass_db_json}}"
    chezmoi_global_args+=(--override-data "${override_data}")
  fi

  chezmoi "${chezmoi_global_args[@]}" init --dry-run --source "${DOTFILES}"

  success "Bootstrap complete! Please restart your terminal or run 'exec zsh'."
}

main "$@"
