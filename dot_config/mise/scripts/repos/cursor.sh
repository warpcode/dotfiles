#!/usr/bin/env bash
# repos/cursor.sh — Cursor (Anysphere)
set -euo pipefail
# shellcheck source=../lib/repo_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/repo_helpers.sh"

if is_apt_based; then
  setup_apt_deb822_repo \
    /usr/share/keyrings/anysphere.gpg \
    https://downloads.cursor.com/keys/anysphere.asc \
    /etc/apt/sources.list.d/cursor.sources \
    "Types: deb
URIs: https://downloads.cursor.com/aptrepo
Suites: stable
Components: main
Architectures: amd64,arm64
Signed-By: /usr/share/keyrings/anysphere.gpg" \
    /etc/apt/sources.list.d/cursor.list  # legacy .list file — remove if present

elif is_dnf_based; then
  setup_dnf_file_repo \
    /etc/yum.repos.d/cursor.repo \
    "[cursor]
name=Cursor
baseurl=https://downloads.cursor.com/yumrepo
enabled=1
gpgcheck=1
gpgkey=https://downloads.cursor.com/keys/anysphere.asc"
fi
