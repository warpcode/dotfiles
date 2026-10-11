#!/usr/bin/env bash
# ~/.config/mise/scripts/lib/os_detect.sh
# Shared helpers for mise repo setup scripts. Source this file, don't execute it.

run_as_root() {
  if [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

info() { printf '💬 %b\n' "$1"; }
warn() { printf '⚠️  %b\n' "$1" >&2; }

# Populate OS identity from /etc/os-release (sourced once)
if [[ -z "${_REPOS_OS_ID:-}" ]]; then
  _REPOS_OS_ID=""
  _REPOS_OS_ID_LIKE=""
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    _REPOS_OS_ID="${ID:-}"
    _REPOS_OS_ID_LIKE="${ID_LIKE:-}"
  fi
  export _REPOS_OS_ID _REPOS_OS_ID_LIKE
fi

is_apt_based() {
  [[ "${_REPOS_OS_ID}" == "ubuntu" || "${_REPOS_OS_ID}" == "debian" ]] \
    || printf '%s' "${_REPOS_OS_ID_LIKE}" | grep -qE "(ubuntu|debian)"
}

is_dnf_based() {
  [[ "${_REPOS_OS_ID}" == "fedora" || "${_REPOS_OS_ID}" == "rhel" || "${_REPOS_OS_ID}" == "centos" ]] \
    || printf '%s' "${_REPOS_OS_ID_LIKE}" | grep -qE "(fedora|rhel)"
}
