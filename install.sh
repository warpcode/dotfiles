#!/bin/bash
#
# Bootstraps the dotfiles repository and dependencies using Chezmoi.

set -euo pipefail
trap 'printf "\n"; exit 130' INT TERM

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

#######################################
# Verifies the SHA-256 checksum of a downloaded file.
# Arguments:
#   $1 - File path to verify.
#   $@ - One or more expected SHA-256 hashes (allowlist).
# Returns:
#   0 if actual hash matches any expected hash, 1 otherwise.
#######################################
verify_checksum() {
  local filepath="$1"
  shift
  if [[ ! -f "${filepath}" ]]; then
    err "Checksum verification failed: file does not exist: ${filepath}"
    return 1
  fi

  local actual_hash=""
  if command -v sha256sum >/dev/null 2>&1; then
    actual_hash="$(sha256sum "${filepath}" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual_hash="$(shasum -a 256 "${filepath}" | awk '{print $1}')"
  elif command -v openssl >/dev/null 2>&1; then
    actual_hash="$(openssl dgst -sha256 "${filepath}" | awk '{print $NF}')"
  else
    err "Checksum verification failed: no SHA-256 tool available (sha256sum, shasum, openssl)"
    return 1
  fi

  actual_hash="$(echo "${actual_hash}" | tr '[:upper:]' '[:lower:]')"

  local expected_hash
  for expected_hash in "$@"; do
    expected_hash="$(echo "${expected_hash}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${actual_hash}" == "${expected_hash}" ]]; then
      return 0
    fi
  done

  err "Integrity check failed for ${filepath}"
  err "Actual SHA-256:   ${actual_hash}"
  err "Expected SHA-256: $*"
  return 1
}

#######################################
# Detects the Linux distribution identifier from os-release.
# Arguments:
#   $1 - Optional path to os-release file (defaults to /etc/os-release).
# Outputs:
#   Writes normalized Linux distribution identifier to stdout (debian, fedora, arch, linux).
#######################################
# shellcheck disable=SC2120
detect_linux_distro() {
  local os_release_file="${1:-${OS_RELEASE_PATH:-/etc/os-release}}"
  local os_id="linux"

  if [[ -f "${os_release_file}" ]]; then
    os_id="$(grep -E '^ID=' "${os_release_file}" 2>/dev/null \
      | cut -d= -f2 \
      | tr -d '"' || echo "linux")"
  fi

  case "${os_id}" in
    ubuntu|debian) echo "debian" ;;
    fedora|arch) echo "${os_id}" ;;
    *) echo "linux" ;;
  esac
}

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
      detect_linux_distro
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
OS_NAME="$(detect_os)"
readonly OS_NAME

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
    local brew_install_script
    brew_install_script="$(mktemp -t homebrew-bootstrap-XXXXXX.sh)"

    # Default allowlist hashes pin known versions of the Homebrew install script.
    # Use HOMEBREW_INSTALL_SHA256 env var to override them if needed.
    local default_brew_hashes="5f333bbe53bc490e51e7ccb1df8779b3dd6ee73a1a7379efda216edb08ccb148"
    local expected_brew_sha256="${HOMEBREW_INSTALL_SHA256:-${default_brew_hashes}}"

    if curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > "${brew_install_script}" && [[ -s "${brew_install_script}" ]]; then
      if verify_checksum "${brew_install_script}" ${expected_brew_sha256}; then
        if ! /bin/bash "${brew_install_script}"; then
          err "Failed to execute Homebrew installer"
          rm -f "${brew_install_script}"
          return 1
        fi
        rm -f "${brew_install_script}"
      else
        err "Failed integrity check for Homebrew installer"
        rm -f "${brew_install_script}"
        return 1
      fi
    else
      err "Failed to download Homebrew installer"
      rm -f "${brew_install_script}"
      return 1
    fi
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
# Parses command line arguments.
# Arguments:
#   $@ - Command line arguments.
# Sets variables in caller scope:
#   dotfiles_profile, git_name, git_email, keepass_db
#######################################
parse_args() {
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
}

#######################################
# Ensures chezmoi is installed.
#######################################
ensure_chezmoi() {
  if command -v chezmoi >/dev/null; then
    return 0
  fi

  info "Installing chezmoi..."
  if [[ "${OS_NAME}" == "macos" ]]; then
    brew install -y chezmoi || true
  else
    mkdir -p "${HOME}/.local/bin"
    local chezmoi_install_script
    chezmoi_install_script="$(mktemp -t chezmoi-bootstrap-XXXXXX.sh)"

    # Default allowlist hashes pin known versions of the chezmoi install script.
    # These may go stale when upstream updates the script.
    # Use CHEZMOI_INSTALL_SHA256 env var to override them if needed.
    local default_chezmoi_hashes="d92ac6044ecfcd716c0c1d0512693e7d91c3002591cd6c871bb94ef227919982 d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512"
    local expected_chezmoi_sha256="${CHEZMOI_INSTALL_SHA256:-${default_chezmoi_hashes}}"

    if curl -fsSL https://chezmoi.io/get > "${chezmoi_install_script}" && [[ -s "${chezmoi_install_script}" ]]; then
      if verify_checksum "${chezmoi_install_script}" ${expected_chezmoi_sha256}; then
        if ! sh "${chezmoi_install_script}" -b "${HOME}/.local/bin"; then
          err "Failed to execute chezmoi installer"
          rm -f "${chezmoi_install_script}"
          exit 1
        fi
        rm -f "${chezmoi_install_script}"
      else
        err "Failed integrity check for chezmoi installer"
        rm -f "${chezmoi_install_script}"
        exit 1
      fi
    else
      err "Failed to download chezmoi installer"
      rm -f "${chezmoi_install_script}"
      exit 1
    fi
  fi
}

#######################################
# Ensures mise is installed.
#######################################
ensure_mise() {
  if [[ -f "${HOME}/.local/bin/mise" ]] || [[ "${OS_NAME}" == "macos" && -x "$(command -v mise)" ]]; then
    success "Mise is already installed, skipping installation."
    return 0
  fi

  info "Installing mise..."
  if [[ "${OS_NAME}" == "macos" ]]; then
    brew install -y mise || true
  else
    mkdir -p "${HOME}/.local/bin"
    local mise_install_script
    mise_install_script="$(mktemp -t mise-bootstrap-XXXXXX.sh)"

    # Default allowlist hashes pin known versions of the mise install script.
    # These may go stale when upstream updates the script.
    # Use MISE_INSTALL_SHA256 env var to override them if needed.
    local default_mise_hashes="82d35715f9d54b9ca4ff5b909ebeb4f4ded457d4fae15814db2fe6da5b943e1f 0f8c5212184c41bae5597fc4abbbd032cb7716021e9be1c6c5b720e022af449d 9f4fe9fc83d98ea5e39cbd5c900e9ad4875e39bdabf8e301ae17f0fce9cb5867 61cb4d61d523a90fc9c479891897f8d0bbf0f622bd909119c06d32cd2202a414"
    local expected_mise_sha256="${MISE_INSTALL_SHA256:-${default_mise_hashes}}"

    if curl -fsSL https://mise.run > "${mise_install_script}" && [[ -s "${mise_install_script}" ]]; then
      if verify_checksum "${mise_install_script}" ${expected_mise_sha256}; then
        if ! sh "${mise_install_script}"; then
          err "Failed to execute mise installer"
          rm -f "${mise_install_script}"
          exit 1
        fi
        rm -f "${mise_install_script}"
      else
        err "Failed integrity check for mise installer"
        rm -f "${mise_install_script}"
        exit 1
      fi
    else
      err "Failed to download mise installer"
      rm -f "${mise_install_script}"
      exit 1
    fi
  fi
  hash -r 2>/dev/null || true
}

#######################################
# Returns the path to the mise binary.
# Outputs:
#   Writes path to stdout.
#######################################
get_mise_bin() {
  if [[ "${OS_NAME}" == "macos" ]] && command -v mise &>/dev/null; then
    command -v mise
  else
    echo "${HOME}/.local/bin/mise"
  fi
}

#######################################
# Applies dotfiles via chezmoi.
# Arguments:
#   $1 - profile
#   $2 - git_name
#   $3 - git_email
#   $4 - keepass_db
#######################################
apply_chezmoi_dotfiles() {
  local profile="$1"
  local git_name="$2"
  local git_email="$3"
  local keepass_db="$4"

  info "Applying dotfiles via Chezmoi..."
  # This will trigger:
  # - run_once_after_05-system.sh (install system pkgs)
  # - run_once_after_06-repositories.sh (setup 3rd party repos)
  # - run_once_after_10-set-zsh.sh (set default shell)
  local -a chezmoi_global_args=()
  # Build --override-data JSON for template variables
  # chezmoi --override-data accepts a JSON string as a global flag (before subcommand)
  local override_data="{}"
  if [[ -n "${profile}" || -n "${git_name}" || -n "${git_email}" || -n "${keepass_db}" ]]; then
    override_data="$(jq -cn \
      --arg profile "${profile}" \
      --arg git_name "${git_name}" \
      --arg git_email "${git_email}" \
      --arg keepass_db "${keepass_db}" \
      '{profile: $profile, git_name: $git_name, git_email: $git_email, keepass_db: $keepass_db} | with_entries(select(.value != ""))')"
    chezmoi_global_args+=(--override-data "${override_data}")
  fi

  export PAGER=cat
  chezmoi "${chezmoi_global_args[@]}" init --apply --source "${DOTFILES}"
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

  parse_args "$@"

  if [[ -n "${dotfiles_profile}" ]]; then
    success "Profile set via argument to: ${dotfiles_profile}"
  fi

  # mise loads config.toml / mise.toml unconditionally, plus config.{env}.toml and
  # mise.{env}.toml for each comma-separated entry in MISE_ENV. Include the OS
  # env on macOS so mise.macos.toml (brew packages) applies there.
  if [[ "${OS_NAME}" == "macos" ]]; then
    export MISE_ENV="macos,${dotfiles_profile:-default}"
  else
    export MISE_ENV="${dotfiles_profile:-default}"
  fi
  info "MISE_ENV set to: ${MISE_ENV}"

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
  ensure_chezmoi

  export PATH="${HOME}/.local/bin:${PATH}"

  # install mise if not already installed
  ensure_mise

  # Bootstrap system packages via mise before chezmoi applies dotfiles
  local mise_bin
  mise_bin="$(get_mise_bin)"
  info "Bootstrapping system packages via mise..."
  # Report but do not abort: a partial package install should not block the
  # dotfile apply that follows, but it must not be silently swallowed either.
  if ! "${mise_bin}" bootstrap --only packages -y; then
    err "mise bootstrap failed - some system packages were not installed"
  fi

  # Apply dotfiles via chezmoi
  apply_chezmoi_dotfiles "${dotfiles_profile}" "${git_name}" "${git_email}" "${keepass_db}"

  info "Installing mise tools (llama.cpp, ollama, etc)..."
  if ! "${mise_bin}" install; then
    err "mise install failed - some tools were not installed"
  fi

  success "Bootstrap complete! Please restart your terminal or run 'exec zsh'."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
