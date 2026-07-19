#!/usr/bin/env bash
# ~/.config/mise/scripts/setup_repos.sh
# Entry point for the mise [bootstrap.hooks.pre-packages] hook.
# Sources each repo script in scripts/repos/ then updates the package manager.
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  exit 0
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/os_detect.sh
source "${SCRIPTS_DIR}/lib/os_detect.sh"

# Run every repo script in order
for repo_script in "${SCRIPTS_DIR}/repos/"*.sh; do
  [[ -f "${repo_script}" ]] || continue
  bash "${repo_script}"
done

# Update package manager index after repos are configured
if command -v apt-get >/dev/null 2>&1; then
  info "Updating apt repositories..."
  run_as_root apt-get update -qq
elif command -v dnf >/dev/null 2>&1; then
  info "Updating dnf repositories..."
  run_as_root dnf check-update -q || true
elif command -v pacman >/dev/null 2>&1; then
  info "Updating pacman repositories..."
  run_as_root pacman -Sy --noconfirm
fi
