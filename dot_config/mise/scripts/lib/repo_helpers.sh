#!/usr/bin/env bash
# ~/.config/mise/scripts/lib/repo_helpers.sh
# Reusable helpers for idempotent package repository setup.
# Source this file; it automatically sources os_detect.sh.

# shellcheck source=os_detect.sh
source "$(dirname "${BASH_SOURCE[0]}")/os_detect.sh"

_setup_apt_keyring() {
  local keyring_path="$1" key_url="$2"
  run_as_root install -m 0755 -d "$(dirname "${keyring_path}")"
  if [[ ! -f "${keyring_path}" ]] || { [[ "${keyring_path}" == *.asc ]] && ! grep -q "BEGIN PGP PUBLIC KEY" "${keyring_path}" 2>/dev/null; }; then
    if [[ "${keyring_path}" == *.asc ]]; then
      curl -fsSL "${key_url}" | run_as_root tee "${keyring_path}" >/dev/null
    else
      curl -fsSL "${key_url}" \
        | run_as_root gpg --dearmor --yes -o "${keyring_path}" 2>/dev/null || true
    fi
    run_as_root chmod a+r "${keyring_path}" 2>/dev/null || true
  fi
}

# ---------------------------------------------------------------------------
# APT — classic .list format
#
# Usage:
#   setup_apt_list_repo <keyring_path> <key_url> <list_path> <repo_line> \
#                       [legacy_file_to_remove ...]
# ---------------------------------------------------------------------------
setup_apt_list_repo() {
  local keyring_path="$1" key_url="$2" list_path="$3" repo_line="$4"
  shift 4

  for legacy in "$@"; do
    run_as_root rm -f "${legacy}" 2>/dev/null || true
  done

  _setup_apt_keyring "${keyring_path}" "${key_url}"

  if [[ ! -f "${list_path}" ]]; then
    info "Configuring $(basename "${list_path}" .list) repository..."
    printf '%s\n' "${repo_line}" | run_as_root tee "${list_path}" >/dev/null
  fi
}

# ---------------------------------------------------------------------------
# APT — DEB822 .sources format
#
# Usage:
#   setup_apt_deb822_repo <keyring_path> <key_url> <sources_path> <content> \
#                         [legacy_file_to_remove ...]
# ---------------------------------------------------------------------------
setup_apt_deb822_repo() {
  local keyring_path="$1" key_url="$2" sources_path="$3" content="$4"
  shift 4

  for legacy in "$@"; do
    run_as_root rm -f "${legacy}" 2>/dev/null || true
  done

  _setup_apt_keyring "${keyring_path}" "${key_url}"

  if [[ ! -f "${sources_path}" ]]; then
    info "Configuring $(basename "${sources_path}" .sources) repository..."
    printf '%s\n' "${content}" | run_as_root tee "${sources_path}" >/dev/null
  fi
}

# ---------------------------------------------------------------------------
# DNF — inline .repo file
#
# Usage:
#   setup_dnf_file_repo <repo_file> <content>
# ---------------------------------------------------------------------------
setup_dnf_file_repo() {
  local repo_file="$1" content="$2"
  if [[ ! -f "${repo_file}" ]]; then
    info "Configuring $(basename "${repo_file}" .repo) repository..."
    printf '%s\n' "${content}" | run_as_root tee "${repo_file}" >/dev/null
  fi
}

# ---------------------------------------------------------------------------
# DNF — dnf config-manager --add-repo
#
# Usage:
#   setup_dnf_config_manager_repo <expected_repo_file> <repo_url>
# ---------------------------------------------------------------------------
setup_dnf_config_manager_repo() {
  local repo_file="$1" repo_url="$2"
  if [[ ! -f "${repo_file}" ]]; then
    info "Configuring $(basename "${repo_file}" .repo) repository..."
    run_as_root dnf config-manager --add-repo "${repo_url}"
  fi
}
