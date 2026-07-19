#!/usr/bin/env bash
# repos/flatpak.sh — Flatpak and Flathub Repo Setup
set -euo pipefail
# shellcheck source=../lib/repo_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/repo_helpers.sh"

# Install flatpak command if not already installed
if ! command -v flatpak >/dev/null 2>&1; then
  info "Installing flatpak..."
  if is_apt_based; then
    run_as_root apt-get install -y -qq flatpak
  elif is_dnf_based; then
    run_as_root dnf install -y -q flatpak
  elif [[ "${_REPOS_OS_ID:-}" == "arch" || "${_REPOS_OS_ID_LIKE:-}" == *"arch"* ]]; then
    run_as_root pacman -S --noconfirm flatpak
  fi
fi

# Add default flathub repo if not present
if command -v flatpak >/dev/null 2>&1; then
  if ! flatpak remote-list | grep -q "flathub"; then
    info "Adding Flathub repository to flatpak..."
    run_as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
fi
