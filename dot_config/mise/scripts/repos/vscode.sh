#!/usr/bin/env bash
# repos/vscode.sh — Visual Studio Code
set -euo pipefail
# shellcheck source=../lib/repo_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/repo_helpers.sh"

if is_apt_based; then
  setup_apt_list_repo \
    /etc/apt/keyrings/packages.microsoft.gpg \
    https://packages.microsoft.com/keys/microsoft.asc \
    /etc/apt/sources.list.d/vscode.list \
    "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    /etc/apt/sources.list.d/vscode.sources  # legacy DEB822 file — remove if present

elif is_dnf_based; then
  setup_dnf_file_repo \
    /etc/yum.repos.d/vscode.repo \
    "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc"
fi
