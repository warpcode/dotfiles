#!/usr/bin/env bash
#
# Worktree overview: list worktrees, detect stale ones (branch pruned/gone),
# prune stale administrative data, remove a worktree (with --remove <path>),
# or create an isolated worktree (with --create <branch>).
#
# Usage: ./worktrees.sh [--create <branch>] [--base <ref>] [--path <dir>] [--no-fetch]
#                       [--remove <path>] [--raw|--raw-output]

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
  --create <branch>  Create isolated worktree for branch and merge base ref
  --base <ref>       Base ref to merge during --create (default: origin/master)
  --path <dir>       Custom directory path for --create (default: /tmp/wt-<branch>-<pid>)
  --no-fetch         Skip remote fetch during --create
  --remove <path>    Remove the specified worktree path (git worktree remove)
  --raw, --raw-output Output raw worktree list (git worktree list --porcelain)
  -h, --help         Show this help message
USAGE_EOF
}

#######################################
# Create an isolated worktree for a branch and merge base.
#######################################
create_worktree() {
  local branch="$1"
  local base="$2"
  local target_dir="$3"
  local do_fetch="$4"

  if [[ -z "${branch}" ]]; then
    err "Branch name required for --create."
    exit 1
  fi

  if [[ "${do_fetch}" == "yes" ]] && git remote | grep -q "^origin$"; then
    git fetch origin "${branch}" 2>/dev/null || true
    local base_remote="${base#origin/}"
    git fetch origin "${base_remote}" 2>/dev/null || true
  fi

  if [[ -z "${target_dir}" ]]; then
    local slug
    slug="$(echo "${branch}" | tr '/' '-' | tr -cd '[:alnum:]-_')"
    target_dir="/tmp/wt-${slug}-$$"
  fi

  if [[ -d "${target_dir}" ]]; then
    err "Target directory already exists: ${target_dir}"
    exit 1
  fi

  if git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null; then
    git worktree add "${target_dir}" "${branch}" >/dev/null 2>&1
  elif git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null; then
    git worktree add "${target_dir}" -b "${branch}" "origin/${branch}" >/dev/null 2>&1
  else
    git worktree add "${target_dir}" -b "${branch}" "${base}" >/dev/null 2>&1
  fi

  if git -C "${target_dir}" -c core.editor=true merge --no-edit "${base}" >/dev/null 2>&1; then
    echo "# Worktree Created: Success"
    echo ""
    echo "Worktree ready at: ${target_dir}"
    echo "Branch '${branch}' cleanly merged '${base}'."
    exit 0
  else
    echo "# Worktree Created: Conflict Detected"
    echo ""
    echo "Worktree ready at: ${target_dir}"
    echo "Merge conflict encountered while merging '${base}' into '${branch}'."
    echo ""
    echo "### Conflicting Files:"
    git -C "${target_dir}" diff --name-only --diff-filter=U | sed 's/^/  - /'
    echo ""
    echo "Resolve conflicts inside '${target_dir}', run tests, commit, then remove with:"
    echo "  worktrees.sh --remove ${target_dir}"
    exit 2
  fi
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
  local create_branch=""
  local base_ref="origin/master"
  local target_path=""
  local do_fetch="yes"
  local raw="no"

  local args=("$@")
  local i=0
  while (( i < ${#args[@]} )); do
    case "${args[$i]}" in
      --create)
        action="--create"
        create_branch="${args[$((i + 1))]:-}"
        (( i += 2 ))
        ;;
      --base)
        base_ref="${args[$((i + 1))]:-}"
        (( i += 2 ))
        ;;
      --path)
        target_path="${args[$((i + 1))]:-}"
        (( i += 2 ))
        ;;
      --no-fetch)
        do_fetch="no"
        (( i += 1 ))
        ;;
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

  if [[ "${action}" == "--create" ]]; then
    create_worktree "${create_branch}" "${base_ref}" "${target_path}" "${do_fetch}"
  fi

  if [[ "${raw}" == "yes" ]]; then
    git worktree list --porcelain
    exit 0
  fi

  # ── Remove a worktree (explicit) ────────────────────────────────────
  if [[ "${action}" == "--remove" && -n "${target}" ]]; then
    echo "## Remove worktree: ${target}"
    echo ""
    git worktree remove --force "${target}" 2>&1 | sed 's/^/  /' || true
    git worktree prune 2>&1 | sed 's/^/  /' || true
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
}

main "$@"
