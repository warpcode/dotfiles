#!/usr/bin/env bash
#
# Stash overview: list all stashes with ref, message, age, and changed files.
# Optionally filters stashes older than N days and drops candidates.
#
# Usage: ./stash.sh [--older-than N] [--drop] [--raw|--raw-output]

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
Usage: ./stash.sh [options]

Options:
  --older-than N     Filter candidate stashes older than N days
  --drop             Drop the candidate stashes (older than N days or all if none specified)
  --raw, --raw-output Output raw stash list and details
  -h, --help         Show this help message
USAGE_EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local older_than=""
  local drop="no"
  local raw="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --older-than)
        if [[ $# -lt 2 || -z "$2" ]]; then
          err "Option --older-than requires a numeric argument."
          exit 1
        fi
        older_than="$2"
        shift 2
        ;;
      --older-than=*)
        older_than="${1#*=}"
        shift
        ;;
      --drop)
        drop="yes"
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

  local count
  count="$(git stash list 2>/dev/null | wc -l | tr -d ' ')"

  if [[ "${raw}" == "yes" ]]; then
    git stash list --format='%gd|%ct|%gs'
    if (( count > 0 )); then
      echo ""
      local i=0
      while (( i < count )); do
        echo "=== stash@{$i} ==="
        git stash show --include-untracked "stash@{$i}" 2>/dev/null || true
        (( i += 1 ))
      done
    fi
    exit 0
  fi

  echo "# Stashes: ${count}"
  echo ""

  if [[ "${count}" == "0" ]]; then
    echo "No stashes."
    exit 0
  fi

  echo "| Ref | Message | Age |"
  echo "|-----|---------|-----|"
  git stash list --format='| %gd | %gs | %cr |'
  echo ""

  if [[ -n "${older_than}" ]]; then
    local now cutoff
    now="$(date +%s)"
    cutoff=$(( now - older_than * 86400 ))

    echo "## Stashes older than ${older_than} days"
    echo ""
    local candidates=()
    local ref ts msg
    while IFS='|' read -r ref ts msg; do
      if (( ts < cutoff )); then
        echo "  - ${ref} (${msg})"
        candidates+=("${ref}")
      fi
    done < <(git stash list --format='%gd|%ct|%gs')

    if (( ${#candidates[@]} == 0 )); then
      echo "  None."
    else
      echo ""
      if [[ "${drop}" == "yes" ]]; then
        echo "  Dropping candidates:"
        local idx
        for (( idx = ${#candidates[@]} - 1; idx >= 0; idx-- )); do
          ref="${candidates[idx]}"
          git stash drop "${ref}" 2>&1 | sed 's/^/    /'
        done
      fi
    fi
    echo ""
  fi

  echo "## Changed files per stash"
  echo ""
  local i=0
  while (( i < count )); do
    echo "### stash@{$i}"
    local files
    files="$(git stash show --include-untracked --name-only "stash@{$i}" 2>/dev/null)"
    if [[ -n "${files}" ]]; then
      while IFS= read -r line; do
        echo "  - ${line}"
      done <<< "${files}"
    else
      echo "  (no file changes)"
    fi
    echo ""
    (( i += 1 ))
  done
}

main "$@"
