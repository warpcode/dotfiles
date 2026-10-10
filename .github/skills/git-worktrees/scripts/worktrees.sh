#!/usr/bin/env bash
#
# Worktree overview: list worktrees, detect stale ones (branch pruned/gone),
# prune stale administrative data, and (with --remove <path>) remove a
# worktree. Pruning is non-destructive; removal requires --remove.
#
# Usage: ./worktrees.sh [--remove <path>] [--raw|--raw-output]

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
Usage: ./worktrees.sh [options]

Options:
  --remove <path>    Remove the specified worktree path (git worktree remove)
  --raw, --raw-output Output raw worktree list (git worktree list --porcelain)
  -h, --help         Show this help message
USAGE_EOF
}

#######################################
# Detect stale worktrees from the porcelain listing.
# Outputs:
#   Paths of stale worktrees, one per line.
#######################################
get_stale_worktrees() {
  local path=""
  local stale="no"
  while IFS= read -r line; do
    case "${line}" in
      worktree*)
        path="${line#worktree }"
        stale="no"
        ;;
      prunable*|*"(gone)"*)
        stale="yes"
        ;;
      "")
        if [[ "${stale}" == "yes" ]]; then
          echo "${path}"
        fi
        path=""
        stale="no"
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)
  # Flush the last entry
  if [[ "${stale}" == "yes" && -n "${path}" ]]; then
    echo "${path}"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local action=""
  local target=""
  local raw="no"

  local args=("$@")
  local i=0
  while (( i < ${#args[@]} )); do
    case "${args[$i]}" in
      --remove)
        action="--remove"
        target="${args[$((i + 1))]:-}"
        (( i += 2 ))
        ;;
      --raw|--raw-output)
        raw="yes"
        (( i += 1 ))
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        err "Unknown argument: ${args[$i]}"
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
    git worktree list --porcelain
    exit 0
  fi

  echo "# Worktrees"
  echo ""

  # ── 1. List worktrees ────────────────────────────────────────────────
  echo "## Active Worktrees"
  echo ""
  if git worktree list >/dev/null 2>&1; then
    git worktree list
  else
    echo "  None."
  fi
  echo ""

  # ── 2. Stale worktrees ───────────────────────────────────────────────
  echo "## Stale Worktrees (branch pruned/gone)"
  echo ""
  local stale
  stale="$(get_stale_worktrees)"
  if [[ -n "${stale}" ]]; then
    while IFS= read -r path; do
      echo "  - ${path}"
    done <<< "${stale}"
  else
    echo "  None detected."
  fi
  echo ""

  # ── 3. Prune stale administrative data ───────────────────────────────
  echo "## Prune stale administrative data"
  echo ""
  git worktree prune 2>&1 | sed 's/^/  /' || true
  echo ""

  # ── 4. Remove a worktree (explicit) ──────────────────────────────────
  if [[ "${action}" == "--remove" && -n "${target}" ]]; then
    echo "## Remove worktree: ${target}"
    echo ""
    git worktree remove "${target}" 2>&1 | sed 's/^/  /' || true
  fi
}

main "$@"
