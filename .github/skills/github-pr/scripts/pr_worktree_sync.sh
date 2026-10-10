#!/usr/bin/env bash
#
# pr_worktree_sync.sh - Author-side PR branch synchronization & conflict resolution.
#
# Creates an isolated git worktree in /tmp/, checks out the target PR branch,
# merges the base branch non-interactively, reports conflict or success state,
# and cleans up the worktree on demand.
#
# Usage:
#   ./pr_worktree_sync.sh setup --branch <branch> [--base <base>] [--dir <path>] [--no-fetch]
#   ./pr_worktree_sync.sh status --dir <path>
#   ./pr_worktree_sync.sh cleanup --dir <path>
#   ./pr_worktree_sync.sh -h | --help
#
# NOTE: Staged in github-pr for now; scheduled to migrate to git-worktrees once PR #171 lands.

set -euo pipefail
export PAGER=cat

print_usage() {
  cat << 'USAGE_EOF'
Usage:
  pr_worktree_sync.sh setup --branch <branch> [--base <base>] [--dir <path>] [--no-fetch]
  pr_worktree_sync.sh status --dir <path>
  pr_worktree_sync.sh cleanup --dir <path>
  pr_worktree_sync.sh -h | --help

Commands:
  setup     Fetch branch and create isolated worktree, then merge base branch.
  status    Report merge conflict, unstaged/staged changes, and branch status in worktree.
  cleanup   Remove isolated worktree and prune worktree metadata.

Options:
  --branch <name>  Name of the PR feature branch (required for setup)
  --base <ref>     Base branch or ref to merge (default: origin/master)
  --dir <path>     Directory path for worktree (default: /tmp/wt-<branch>-<pid>)
  --no-fetch       Skip remote git fetch step
  -h, --help       Show this help message
USAGE_EOF
}

cmd_setup() {
  local branch=""
  local base="origin/master"
  local target_dir=""
  local do_fetch=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --branch)
        branch="${2:-}"
        shift 2 || true
        ;;
      --base)
        base="${2:-}"
        shift 2 || true
        ;;
      --dir)
        target_dir="${2:-}"
        shift 2 || true
        ;;
      --no-fetch)
        do_fetch=0
        shift
        ;;
      *)
        echo "Error: Unknown setup option: $1" >&2
        print_usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$branch" ]]; then
    echo "Error: --branch is required for setup." >&2
    exit 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Must be run inside a git repository." >&2
    exit 1
  fi

  if [[ $do_fetch -eq 1 ]] && git remote | grep -q "^origin$"; then
    git fetch origin "$branch" 2>/dev/null || true
    local base_remote_branch="${base#origin/}"
    git fetch origin "$base_remote_branch" 2>/dev/null || true
  fi

  if [[ -z "$target_dir" ]]; then
    local slug
    slug="$(echo "$branch" | tr '/' '-' | tr -cd '[:alnum:]-_')"
    target_dir="/tmp/wt-${slug}-$$"
  fi

  if [[ -d "$target_dir" ]]; then
    echo "Error: Target worktree directory already exists: $target_dir" >&2
    exit 1
  fi

  # Create worktree using origin tracking branch if local does not exist
  if git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
    git worktree add "$target_dir" "$branch" >/dev/null 2>&1
  elif git rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null; then
    git worktree add "$target_dir" -b "$branch" "origin/$branch" >/dev/null 2>&1
  else
    git worktree add "$target_dir" "$branch" >/dev/null 2>&1
  fi

  # Attempt non-interactive merge of the base ref
  if git -C "$target_dir" -c core.editor=true merge --no-edit "$base" >/dev/null 2>&1; then
    echo "# PR Worktree Sync: Success"
    echo ""
    echo "Worktree ready at: $target_dir"
    echo "Branch '$branch' cleanly merged '$base'."
    exit 0
  else
    echo "# PR Worktree Sync: Conflict Detected"
    echo ""
    echo "Worktree ready at: $target_dir"
    echo "Merge conflict encountered while merging '$base' into '$branch'."
    echo ""
    echo "### Conflicting Files:"
    git -C "$target_dir" diff --name-only --diff-filter=U | sed 's/^/  - /'
    echo ""
    echo "Resolve conflicts inside '$target_dir', run tests, commit, then cleanup."
    exit 2
  fi
}

cmd_status() {
  local target_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir)
        target_dir="${2:-}"
        shift 2 || true
        ;;
      *)
        echo "Error: Unknown status option: $1" >&2
        print_usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$target_dir" ]]; then
    echo "Error: --dir is required for status." >&2
    exit 1
  fi

  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory not found: $target_dir" >&2
    exit 1
  fi

  echo "# Worktree Status: $target_dir"
  echo ""
  local current_branch
  current_branch="$(git -C "$target_dir" branch --show-current 2>/dev/null || echo "detached")"
  echo "Current branch: $current_branch"
  echo ""

  local git_dir
  git_dir="$(git -C "$target_dir" rev-parse --git-dir 2>/dev/null || echo "")"
  if [[ -n "$git_dir" && -f "$git_dir/MERGE_HEAD" ]]; then
    echo "State: MERGING (conflicts unresolved)"
    echo ""
    echo "### Unmerged / Conflicting Paths:"
    git -C "$target_dir" diff --name-only --diff-filter=U | sed 's/^/  - /'
    echo ""
  else
    echo "State: CLEAN"
    echo ""
  fi

  echo "### Working Tree Changes:"
  local changes
  changes="$(git -C "$target_dir" status --short 2>/dev/null || true)"
  if [[ -n "$changes" ]]; then
    while IFS= read -r line; do
      printf '  %s\n' "$line"
    done <<< "$changes"
  else
    echo "  No uncommitted changes."
  fi
}

cmd_cleanup() {
  local target_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir)
        target_dir="${2:-}"
        shift 2 || true
        ;;
      *)
        echo "Error: Unknown cleanup option: $1" >&2
        print_usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$target_dir" ]]; then
    echo "Error: --dir is required for cleanup." >&2
    exit 1
  fi

  if [[ -d "$target_dir" ]]; then
    git worktree remove --force "$target_dir" 2>/dev/null || rm -rf "$target_dir"
  fi
  git worktree prune 2>/dev/null || true
  echo "Cleaned up worktree at: $target_dir"
}

main() {
  if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
  fi

  local action="$1"
  shift

  case "$action" in
    setup)
      cmd_setup "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    cleanup)
      cmd_cleanup "$@"
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown command: $action" >&2
      print_usage >&2
      exit 1
      ;;
  esac
}

main "$@"
