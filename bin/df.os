#!/usr/bin/env zsh
#
# df.os - OS and architecture detection utility (standalone).
# Extracted from src/zsh/functions/os.zsh for portability.

emulate -LR zsh
setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
typeset -r SCRIPT_DIR="${0:A:h}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  print -r -- "df.os: $*" >&2
}

# ---------------------------------------------------------------------------
# Detection Functions
# ---------------------------------------------------------------------------

#######################################
# Detect if running in Termux.
# Returns:
#   0 if Termux, 1 otherwise.
#######################################
_is_termux() {
  [[ -n "${TERMUX_VERSION:-}" && -d "${PREFIX:-/nonexistent}" ]]
}

#######################################
# Detect OS family.
# Outputs:
#   One of: macos, debian, fedora, arch, termux, linux, unknown.
#######################################
_family() {
  local os="unknown"
  case "${OSTYPE}" in
    darwin*) os="macos" ;;
    linux*)
      if _is_termux; then
        os="termux"
      elif [[ -f /etc/os-release ]]; then
        local -A os_info
        local line key val
        for line in ${(f)"$(< /etc/os-release)"}; do
          [[ "${line}" == [A-Z_]*=* ]] || continue
          key="${line%%=*}"
          val="${line#*=}"
          val="${${val#[\"\']}%[\"\']}"
          os_info[${key}]="${val}"
        done

        local id="${os_info[ID]}"
        local like="${os_info[ID_LIKE]}"

        case "${id}" in
          ubuntu|debian|pop|kali|linuxmint) os="debian" ;;
          fedora|rhel|centos) os="fedora" ;;
          arch|manjaro) os="arch" ;;
          *)
            if [[ "${like}" == *debian* ]]; then
              os="debian"
            elif [[ "${like}" == *fedora* ]]; then
              os="fedora"
            elif [[ "${like}" == *arch* ]]; then
              os="arch"
            else
              os="${id:-linux}"
            fi
            ;;
        esac
      fi
      ;;
  esac
  print -r -- "${os}"
}

#######################################
# Detect CPU architecture.
# Outputs:
#   One of: amd64, arm64, or raw uname -m value.
#######################################
_arch() {
  local arch
  arch="$(uname -m)"
  case "${arch}" in
    x86_64|amd64)  arch="amd64" ;;
    aarch64|arm64)  arch="arm64" ;;
  esac
  print -r -- "${arch}"
}

#######################################
# Check for a GUI environment.
# Returns:
#   0 if GUI available, 1 if headless.
#######################################
_has_gui() {
  [[ "${OSTYPE}" == darwin* && -z "${SSH_CONNECTION:-}" ]] && return 0
  [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

#######################################
# Check if running headless (no GUI).
# Returns:
#   0 if headless, 1 if GUI available.
#######################################
_is_headless() {
  ! _has_gui
}

#######################################
# Filter input lines by current architecture patterns.
# Arguments:
#   $1 - (optional) Input string. If omitted, reads stdin.
# Outputs:
#   Matching lines to stdout.
#######################################
_filter() {
  local arch
  arch="$(_arch)"
  local p
  case "${arch}" in
    amd64) p="(amd64|x86_64|x64)" ;;
    arm64) p="(arm64|aarch64)" ;;
    *)     p="${arch}" ;;
  esac

  if [[ -n "${1:-}" ]]; then
    local -a lines=(${(f)1})
    print -l ${(M)lines:#(#i)*$~p*}
  else
    local line
    while IFS= read -r line; do
      [[ "${line}" == (#i)*$~p* ]] && print -r -- "${line}"
    done
  fi
}

_usage() {
  print -r -- "Usage: df.os <command>"
  print -r -- ""
  print -r -- "Commands:"
  print -r -- "  family       Detect OS family (macos, debian, arch, etc.)"
  print -r -- "  arch         Detect architecture (amd64, arm64)"
  print -r -- "  has-gui      Check for GUI environment (exit code)"
  print -r -- "  is-headless  Check for headless environment (exit code)"
  print -r -- "  filter [str] Filter input by architecture patterns"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    family)      _family ;;
    arch)        _arch ;;
    has-gui)     _has_gui ;;
    is-headless) _is_headless ;;
    filter)      shift; _filter "$@" ;;
    -h|--help)   _usage ;;
    *)
      err "Unknown command: ${cmd:-<none>}"
      _usage >&2
      return 1
      ;;
  esac
}

main "$@"
