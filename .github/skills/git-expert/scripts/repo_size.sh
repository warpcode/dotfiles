#!/usr/bin/env bash
#
# Repository size and object statistics: report object count, packfile size,
# and loose objects. With --aggressive, expires reflogs and runs git gc --prune=now.
#
# Usage: ./repo_size.sh [--aggressive] [--raw|--raw-output]

set -euo pipefail
export PAGER=cat

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

print_usage() {
  cat <<'USAGE_EOF'
Usage: ./repo_size.sh [options]

Options:
  --aggressive       Expire reflogs and run aggressive garbage collection (git gc --prune=now)
  --raw, --raw-output Output raw object count report (git count-objects -vH)
  -h, --help         Show this help message
USAGE_EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local aggressive="no"
  local raw="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --aggressive)
        aggressive="yes"
        shift
        ;;
      --raw|--raw-output)
        raw="yes"
        shift
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        print_usage >&2
        exit 1
        ;;
    esac
  done

  # Check git is installed
  if ! command -v git >/dev/null 2>&1; then
    err "git is not installed or not in PATH."
    exit 1
  fi

  # Ensure execution inside a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    err "Not inside a git work tree."
    exit 1
  fi

  if [[ "${raw}" == "yes" ]]; then
    git count-objects -vH
    exit 0
  fi

  echo "# Repository Size & Objects"
  echo ""

  echo "## Object Statistics"
  echo ""
  git count-objects -vH
  echo ""

  if [[ "${aggressive}" == "yes" ]]; then
    echo "## Expire reflogs (now)"
    echo ""
    git reflog expire --expire=now --all 2>&1 | sed 's/^/  /' || true
    echo ""
    echo "## git gc --prune=now"
    echo ""
    git gc --prune=now 2>&1 | sed 's/^/  /' || true
    echo ""
    echo "## Size after"
    echo ""
    git count-objects -vH
  else
    echo "(dry-run — pass --aggressive to expire reflogs and run git gc --prune=now)"
  fi
}

main "$@"
