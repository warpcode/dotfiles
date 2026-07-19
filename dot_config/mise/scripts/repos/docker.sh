#!/usr/bin/env bash
# repos/docker.sh — Docker CE
set -euo pipefail
# shellcheck source=../lib/repo_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/repo_helpers.sh"

if is_apt_based; then
  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"

  setup_apt_list_repo \
    /etc/apt/keyrings/docker.asc \
    "https://download.docker.com/linux/${_REPOS_OS_ID}/gpg" \
    /etc/apt/sources.list.d/docker.list \
    "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${_REPOS_OS_ID} ${codename} stable"

elif is_dnf_based; then
  setup_dnf_config_manager_repo \
    /etc/yum.repos.d/docker-ce.repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
fi
