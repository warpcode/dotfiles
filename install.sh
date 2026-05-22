#!/bin/bash
#
# Bootstraps the dotfiles repository and dependencies.

set -euo pipefail

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
  if [[ "$(id -u)" -ne 0 ]]; then
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

readonly DOTFILES_SILENT="${DOTFILES_SILENT:-0}"
readonly DOTFILES_SKIP_CHSHELL="${DOTFILES_SKIP_CHSHELL:-0}"
readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/warpcode/dotfiles.git}"
readonly OS_NAME="$(detect_os)"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

#######################################
# Prints messages to stdout unless silent.
# Globals:
#   DOTFILES_SILENT
# Arguments:
#   $@ - Message to print.
# Outputs:
#   Writes message to stdout.
#######################################
out() {
  if [[ "${DOTFILES_SILENT}" != "1" ]]; then
    printf '%b\n' "$*"
  fi
}

#######################################
# Prints error messages to stderr.
# Arguments:
#   $@ - Error message to print.
# Outputs:
#   Writes timestamped error message to stderr.
#######################################
err() {
  printf '[%s] ❌ %b\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >&2
}

#######################################
# Prints informational messages.
# Arguments:
#   $1 - Info message.
#   $2 - Prefix (optional).
# Outputs:
#   Writes prefixed message to stdout.
#######################################
info() {
  local prefix="${2:-}"
  out "${prefix}💬 $1"
}

#######################################
# Prints success messages.
# Arguments:
#   $1 - Success message.
#   $2 - Prefix (optional).
# Outputs:
#   Writes prefixed message to stdout.
#######################################
success() {
  local prefix="${2:-}"
  out "${prefix}✅ $1"
}

#######################################
# Prints warning messages to stderr.
# Arguments:
#   $1 - Warning message.
#   $2 - Prefix (optional).
# Outputs:
#   Writes prefixed message to stderr.
#######################################
warn() {
  local prefix="${2:-}"
  out "${prefix}⚠️  $1" >&2
}

# ---------------------------------------------------------------------------
# Declarative Packages
# ---------------------------------------------------------------------------

readonly CORE_PACKAGES=(
  "git|apt=git|dnf=git|pacman=git|brew=git|termux=git"
  "zsh|apt=zsh|dnf=zsh|pacman=zsh|brew=zsh|termux=zsh"
  "curl|apt=curl|dnf=curl|pacman=curl|brew=curl|termux=curl"
  "dialog|apt=dialog|dnf=dialog|pacman=dialog|brew=dialog|termux=dialog"
)

readonly SYSTEM_PACKAGES=(
  "build-tools|apt=build-essential|dnf=@development-tools|pacman=base-devel"
  "make|apt=make|dnf=make|pacman=make|brew=make"
  "ca-certificates|apt=ca-certificates|dnf=ca-certificates|pacman=ca-certificates"
  "gnupg|apt=gnupg2|dnf=gnupg2|brew=gnupg"
  "libatomic|apt=libatomic1|dnf=libatomic|pacman=gcc-libs"
  "openssl|apt=openssl|dnf=openssl|brew=openssl"
  "pkg-config|apt=pkg-config|dnf=pkgconf-pkg-config|brew=pkg-config"
  "unzip|apt=unzip|dnf=unzip|brew=unzip"
  "secret-tool|apt=libsecret-tools|dnf=libsecret"
  "bc|apt=bc|dnf=bc|pacman=bc|brew=bc"
)

readonly INTEGRATION_PACKAGES=(
  "flatpak|apt=flatpak|dnf=flatpak|pacman=flatpak"
  "mise|apt=mise|dnf=mise|pacman=mise|brew=mise"
  "docker|brew=docker|apt=docker-ce docker-compose-plugin|brew_cask=docker-desktop"
)

readonly RUNTIME_PACKAGES=(
  "python3|mise=python@3.12"
  "node|mise=node@latest"
  "rust|mise=rust"
  "go|mise=go"
  "deno|mise=deno"
  "php|apt=php-cli|dnf=php-cli|pacman=php|brew=php"
)

readonly CLI_TOOLS=(
  "openssh|apt=openssh-client|dnf=openssh-clients|pacman=openssh"
  "tmux|apt=tmux|dnf=tmux|pacman=tmux|brew=tmux|snap=tmux|termux=tmux"
  "screen|apt=screen|dnf=screen|pacman=screen|brew=screen"
  "rsync|apt=rsync|dnf=rsync|pacman=rsync|brew=rsync"
  "jq|mise=jq"
  "yq|mise=yq"
  "fzf|mise=fzf"
  "bat|mise=bat"
  "gomplate|mise=gomplate"
  "gh|mise=gh"
  "lazygit|mise=lazygit"
  "neovim|mise=neovim@0.11.6"
  "uv|mise=uv"
)

readonly NPM_PACKAGES=(
  "prettier|npm=prettier"
  "eslint|npm=eslint"
  "typescript-language-server|npm=typescript-language-server"
)

readonly APP_PACKAGES=(
  "discord|flatpak=com.discordapp.Discord|brew_cask=discord|not=work"
  "ffmpeg|apt=ffmpeg|dnf=ffmpeg|pacman=ffmpeg|brew=ffmpeg|not=work"
  "k8slens|snap=kontena-lens --classic|brew_cask=lens|not=work"
  "keepassxc|flatpak=org.keepassxc.KeePassXC|brew_cask=keepassxc|not=work"
  "code|snap=code --classic|apt=code|dnf=code|brew_cask=visual-studio-code|not=work"
  "cursor|apt=cursor|dnf=cursor|brew_cask=cursor|not=work"
  "antigravity|apt=antigravity|dnf=antigravity|brew_cask=antigravity|not=work"
)

readonly AI_PACKAGES=(
  "ai_skills|npm=skills@latest|not=work"
  "copilot-cli|npm=@github/copilot|not=work"
  "gemini-cli|npm=@google/gemini-cli|not=work"
  "ollama|mise=ollama|not=work"
  "opencode|npm=opencode-ai@latest|not=work"
  "kilo|npm=@kilocode/cli|not=work"
  "pi|npm=@mariozechner/pi-coding-agent|not=work"
  "qwen|npm=@qwen-code/qwen-code@latest|not=work"
  "codex|npm=@openai/codex|not=work"
  "claude|npm=@anthropic-ai/claude-code|not=work"
)

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

#######################################
# Installs a package using the appropriate package manager.
# Arguments:
#   $1 - Package entry formatted as "name|mgr1=pkg1|mgr2=pkg2".
# Outputs:
#   Status messages.
#######################################
install_pkg() {
  local item="$1"
  local name specs

  name="${item%%|*}"
  IFS='|' read -r -a specs <<< "${item#*|}"

  local spec key val p=",${DOTFILES_PROFILE:-default},"
  for spec in "${specs[@]}"; do
    key="${spec%%=*}"
    val="${spec#*=}"
    val="${val// /}"
    if [[ "${key}" == "only" && ! ",${val}," == *"${p}"* ]] || \
       [[ "${key}" == "not"  &&   ",${val}," == *"${p}"* ]]; then
      info "Skipping ${name} (profile constraint: ${key}=${val})" "  "
      return 0
    fi
  done

  if command -v "${name}" >/dev/null 2>&1; then
    success "${name} is already installed" "  "
    return 0
  fi

  local mgr pkg
  for spec in "${specs[@]}"; do
    mgr="${spec%%=*}"
    pkg="${spec#*=}"

    if [[ "${mgr}" == "only" || "${mgr}" == "not" ]]; then continue; fi

    if [[ "${mgr}" == "termux" ]]; then
      if ! command -v pkg >/dev/null 2>&1; then continue; fi
    elif ! command -v "${mgr%_cask}" >/dev/null 2>&1; then
      continue
    fi

    local is_installed=1
    local -a pkgs
    read -r -a pkgs <<< "${pkg}"

    local p
    for p in "${pkgs[@]}"; do
      [[ "${p}" == -* ]] && continue

      case "${mgr}" in
        apt|termux)
          dpkg-query -W -f='${Status}' "${p}" 2>/dev/null \
            | grep -q " installed" || is_installed=0
          ;;
        dnf)
          if [[ "${p}" == @* ]]; then
            dnf group list installed "${p#@}" >/dev/null 2>&1 \
              || is_installed=0
          else
            rpm -q "${p}" >/dev/null 2>&1 || is_installed=0
          fi
          ;;
        pacman) pacman -Q "${p}" >/dev/null 2>&1 || is_installed=0 ;;
        brew) brew list "${p}" >/dev/null 2>&1 || is_installed=0 ;;
        brew_cask)
          brew list --cask "${p}" >/dev/null 2>&1 || is_installed=0
          ;;
        flatpak) flatpak info "${p}" >/dev/null 2>&1 || is_installed=0 ;;
        snap) snap list "${p}" >/dev/null 2>&1 || is_installed=0 ;;
        mise) mise where "${p}" >/dev/null 2>&1 || is_installed=0 ;;
        npm) npm ls -g "${p%%@*}" >/dev/null 2>&1 || is_installed=0 ;;
      esac

      [[ "${is_installed}" -eq 0 ]] && break
    done

    if [[ "${is_installed}" -eq 1 ]]; then
      success "${name} is already installed via ${mgr}" "  "
      return 0
    fi

    info "Installing ${name} via ${mgr}..." "  "
    local -a cmd=()
    case "${mgr}" in
      apt) cmd=(run_as_root apt install -y "${pkgs[@]}") ;;
      dnf)
        if [[ "${pkg}" == *@* ]]; then
          local -a grps=()
          local g
          for g in "${pkgs[@]}"; do grps+=("${g#@}"); done
          cmd=(run_as_root dnf group install -y "${grps[@]}")
        else
          cmd=(run_as_root dnf install -y "${pkgs[@]}")
        fi
        ;;
      pacman) cmd=(run_as_root pacman -S --noconfirm "${pkgs[@]}") ;;
      brew) cmd=(brew install "${pkgs[@]}") ;;
      brew_cask) cmd=(brew install --cask "${pkgs[@]}") ;;
      flatpak) cmd=(flatpak install -y "${pkgs[@]}") ;;
      snap) cmd=(run_as_root snap install "${pkgs[@]}") ;;
      mise) cmd=(mise use -g "${pkgs[@]}") ;;
      npm) cmd=(npm install -g "${pkgs[@]}") ;;
      termux) cmd=(pkg install -y "${pkgs[@]}") ;;
    esac

    if [[ ${#cmd[@]} -gt 0 ]]; then
      "${cmd[@]}" 2>&1 | sed 's/^/    /'
    fi
    return 0
  done

  warn "${name}: no installer available" "  "
}

#######################################
# Runs Debian/Ubuntu specific setup.
#######################################
setup_debian() {
  info "Setting up Debian/Ubuntu..."
  run_as_root apt update -qq
  run_as_root apt install -y -qq curl ca-certificates gnupg

  local arch
  arch="$(dpkg --print-architecture)"

  local id="ubuntu"
  local version_codename=""
  if [[ -f /etc/os-release ]]; then
    id="$(grep -E '^ID=' /etc/os-release 2>/dev/null \
      | cut -d= -f2 | tr -d '"' || echo "ubuntu")"
    version_codename="$(grep -E '^VERSION_CODENAME=' /etc/os-release \
      2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
  fi

  run_as_root install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]]; then
    info "Configuring GitHub CLI repository..."
    curl -fsSL \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | run_as_root dd \
        of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    printf 'deb [arch=%s signed-by=%s] %s stable main\n' \
      "${arch}" \
      "/usr/share/keyrings/githubcli-archive-keyring.gpg" \
      "https://cli.github.com/packages" \
      | run_as_root tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  fi

  if ! command -v mise >/dev/null; then
    info "Configuring Mise repository..."
    curl -fsSL https://mise.jdx.dev/gpg-key.pub \
      | run_as_root gpg --dearmor \
        -o /etc/apt/keyrings/mise-archive-keyring.gpg 2>/dev/null || true
    printf 'deb [arch=amd64 signed-by=%s] %s stable main\n' \
      "/etc/apt/keyrings/mise-archive-keyring.gpg" \
      "https://mise.jdx.dev/deb" \
      | run_as_root tee /etc/apt/sources.list.d/mise.list > /dev/null
  fi

  if ! command -v docker >/dev/null; then
    info "Configuring Docker repository..."
    curl -fsSL "https://download.docker.com/linux/${id}/gpg" \
      | run_as_root tee /etc/apt/keyrings/docker.asc >/dev/null
    run_as_root chmod a+r /etc/apt/keyrings/docker.asc
    printf 'deb [arch=%s signed-by=%s] %s %s stable\n' \
      "${arch}" \
      "/etc/apt/keyrings/docker.asc" \
      "https://download.docker.com/linux/${id}" \
      "${version_codename}" \
      | run_as_root tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  if [[ ! -f /etc/apt/sources.list.d/cursor.list ]]; then
    info "Configuring Cursor repository..."
    curl -fsSL https://downloads.cursor.com/keys/anysphere.asc \
      | run_as_root gpg --dearmor \
        -o /etc/apt/keyrings/cursor.gpg 2>/dev/null || true
    printf 'deb [arch=amd64,arm64 signed-by=%s] %s stable main\n' \
      "/etc/apt/keyrings/cursor.gpg" \
      "https://downloads.cursor.com/aptrepo" \
      | run_as_root tee /etc/apt/sources.list.d/cursor.list > /dev/null
  fi

  if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    info "Configuring VS Code repository..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | run_as_root gpg --dearmor --yes \
        -o /etc/apt/keyrings/packages.microsoft.gpg 2>/dev/null || true
    printf 'deb [arch=amd64,arm64,armhf signed-by=%s] %s stable main\n' \
      "/etc/apt/keyrings/packages.microsoft.gpg" \
      "https://packages.microsoft.com/repos/code" \
      | run_as_root tee /etc/apt/sources.list.d/vscode.list > /dev/null
  fi

  if [[ ! -f /etc/apt/sources.list.d/antigravity.list ]]; then
    info "Configuring Antigravity repository..."
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg \
      | run_as_root gpg --dearmor --yes \
        -o /etc/apt/keyrings/antigravity-repo-key.gpg 2>/dev/null || true
    printf 'deb [signed-by=%s] %s antigravity-debian main\n' \
      "/etc/apt/keyrings/antigravity-repo-key.gpg" \
      "https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/" \
      | run_as_root tee /etc/apt/sources.list.d/antigravity.list > /dev/null
  fi

  run_as_root apt update -qq
}

#######################################
# Runs Fedora specific setup.
#######################################
setup_fedora() {
  info "Setting up Fedora..."
  run_as_root dnf check-update -q || true
  if ! command -v mise >/dev/null; then
    run_as_root dnf copr enable -y jdxcode/mise
  fi

  if [[ ! -f /etc/yum.repos.d/cursor.repo ]]; then
    info "Configuring Cursor repository..."
    run_as_root tee /etc/yum.repos.d/cursor.repo << 'EOF' >/dev/null
[cursor]
name=Cursor
baseurl=https://downloads.cursor.com/yumrepo
enabled=1
gpgcheck=1
gpgkey=https://downloads.cursor.com/keys/anysphere.asc
EOF
  fi

  if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
    info "Configuring VS Code repository..."
    run_as_root tee /etc/yum.repos.d/vscode.repo << 'EOF' >/dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  fi

  if [[ ! -f /etc/yum.repos.d/antigravity.repo ]]; then
    info "Configuring Antigravity repository..."
    run_as_root tee /etc/yum.repos.d/antigravity.repo << 'EOF' >/dev/null
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOF
  fi

  run_as_root dnf update -y -q
}

#######################################
# Runs Arch Linux specific setup.
#######################################
setup_arch() {
  info "Setting up Arch..."
  run_as_root pacman -Sy -q
}

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
  brew update
}

#######################################
# Runs Termux specific setup.
#######################################
setup_termux() {
  info "Setting up Termux..."
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

  if [[ -d "${DOTFILES_INSTALL_DIR}" && \
        -f "${DOTFILES_INSTALL_DIR}/install.sh" ]]; then
    success "Dotfiles already present at ${DOTFILES_INSTALL_DIR}"
    if [[ -d "${DOTFILES_INSTALL_DIR}/.git" ]]; then
      cd "${DOTFILES_INSTALL_DIR}" || return 1
      info "Initializing submodules..."
      if ! git submodule update --init --recursive --depth 1 --quiet \
        2>/dev/null; then
        warn "Submodule update failed. Falling back to HTTPS URLs..."
        git config --local \
          url."https://github.com/".insteadOf "git@github.com:"
        git submodule sync --recursive >/dev/null 2>&1 || true
        git submodule update --init --recursive --depth 1 --quiet \
          2>/dev/null || true
      fi
    fi
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
    success "zsh is already the default shell."
    return 0
  fi

  if [[ "${DOTFILES_SKIP_CHSHELL}" == "1" ]]; then
    info "Skipping shell change (DOTFILES_SKIP_CHSHELL=1)"
    return 0
  fi

  info "Changing default shell to zsh..."
  if ! command -v chsh >/dev/null; then
    warn "'chsh' not found. Set default shell to ${zsh_path} manually."
    return 0
  fi

  if run_as_root chsh -s "${zsh_path}" "${u}"; then
    success "Default shell changed to zsh successfully."
  else
    warn "Failed to change default shell automatically."
    info "Please run: sudo chsh -s ${zsh_path} ${u}"
  fi
}

#######################################
# Prompts the user to select a dotfiles profile.
# Pure bash — no external dependencies.
# Globals:
#   DOTFILES_PROFILE_FILE, CI
#######################################
select_profile() {
  local profile_file="${HOME}/.dotfiles_profile"
  local detected_profile="default"
  [[ -n "${DOTFILES_PROFILE:-}" ]] && detected_profile="${DOTFILES_PROFILE}"
  [[ -z "${DOTFILES_PROFILE:-}" && -f "${profile_file}" ]] && \
    detected_profile="$(<"${profile_file}")"

  local -a profiles=("default" "work" "phone")
  local selection=""

  if [[ -n "${CI:-}" ]]; then
    selection="${detected_profile}"
    info "Running in CI. Automatically selecting profile: ${selection}"
  else
    local i n=${#profiles[@]} choice
    printf '\n'; info "Available profiles:"
    for i in "${!profiles[@]}"; do
      local cur=""; [[ "${profiles[$i]}" == "${detected_profile}" ]] && \
        cur=" (current)"
      printf '  %s) %s%s\n' "$((i + 1))" "${profiles[$i]}" "${cur}"
    done
    while true; do
      read -r -p "Select profile [1-${n}] (default: ${detected_profile}): " \
        choice </dev/tty
      [[ -z "${choice}" ]] && { selection="${detected_profile}"; break; }
      [[ "${choice}" =~ ^[0-9]+$ ]] && \
        (( choice >= 1 && choice <= n )) && \
        { selection="${profiles[$((choice - 1))]}"; break; }
      printf 'Invalid. Enter 1-%s.\n' "${n}"
    done
  fi

  [[ -z "${selection}" ]] && { err "No profile selected."; exit 1; }
  echo "${selection}" > "${HOME}/.dotfiles_profile"
  export DOTFILES_PROFILE="${selection}"
  success "Profile set to: ${selection}"
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

  # 1. Select profile
  if [[ -n "${dotfiles_profile}" ]]; then
    echo "${dotfiles_profile}" > "${HOME}/.dotfiles_profile"
    export DOTFILES_PROFILE="${dotfiles_profile}"
    success "Profile set via argument to: ${dotfiles_profile}"
  else
    select_profile
  fi

  info "Detected OS: ${OS_NAME}"

  case "${OS_NAME}" in
    debian) setup_debian ;;
    fedora) setup_fedora ;;
    arch)   setup_arch ;;
    macos)  setup_macos ;;
    termux) setup_termux ;;
  esac

  # 2. Install core prerequisites
  local pkg
  for pkg in "${CORE_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  # Refresh command hash after core installations
  hash -r 2>/dev/null || true

  # 3. Set Zsh as default shell
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null)" || zsh_path=""
  if [[ -z "${zsh_path}" ]]; then
    local p
    for p in /usr/bin/zsh /bin/zsh /usr/local/bin/zsh; do
      if [[ -x "${p}" ]]; then
        zsh_path="${p}"
        break
      fi
    done
  fi
  if [[ -n "${zsh_path}" ]]; then
    set_zsh_default "${zsh_path}"
  fi

  # 4. Clone repository
  ensure_dotfiles "${DOTFILES_REPO_URL}"

  # 5. Set up installation directory
  export DOTFILES="${DOTFILES_INSTALL_DIR}"
  cd "${DOTFILES}" || exit 1
  if command -v git >/dev/null; then
    git config --global --add safe.directory "${DOTFILES}"
  fi

  # 6. Install packages
  info "Installing system libraries..."
  for pkg in "${SYSTEM_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  info "Installing package managers & integrations..."
  for pkg in "${INTEGRATION_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
  fi

  export PATH="${HOME}/.local/share/mise/shims:${PATH}"

  info "Installing runtimes..."
  for pkg in "${RUNTIME_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  info "Installing CLI tools..."
  for pkg in "${CLI_TOOLS[@]}"; do install_pkg "${pkg}"; done

  info "Installing NPM global packages..."
  for pkg in "${NPM_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  info "Installing apps & productivity tools..."
  for pkg in "${APP_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  info "Installing AI tools..."
  for pkg in "${AI_PACKAGES[@]}"; do install_pkg "${pkg}"; done

  # 7. Source all functions, then execute recipe configure hooks
  if [[ -f "src/zsh/init.zsh" && -n "${zsh_path}" ]]; then
    "${zsh_path}" -c "source src/zsh/init.zsh && pkg.recipe.configure_all"
  fi

  # 8. Hand off to internal Zsh configuration
  printf '\nBootstrapping dotfiles...\n'
  if [[ -f "src/zsh/init.zsh" && -n "${zsh_path}" ]]; then
    "${zsh_path}" -c "source src/zsh/init.zsh && dotfiles.setup"
  fi

  success "Bootstrap complete! Please restart your terminal or run 'exec zsh'."
}

main "$@"
