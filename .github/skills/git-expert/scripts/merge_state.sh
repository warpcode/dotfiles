#!/usr/bin/env bash
#
# Detect in-progress git operations (merge, rebase, cherry-pick, revert,
# bisect), list conflict files, and summarize staged/unstaged/untracked
# changes. Bundles the checks an AI needs to answer "am I mid-operation?"
# and "what's conflicting?" in one call.
#
# Usage: ./merge_state.sh [--raw|--raw-output]

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Get the git dir (handles worktrees).
# Outputs:
#   Path to the git metadata directory.
#######################################
get_git_dir() {
  git rev-parse --git-dir 2>/dev/null
}

#######################################
# Detect an in-progress operation.
# Globals:
#   GIT_DIR - set by caller.
# Outputs:
#   Operation name, or empty string if none.
#######################################
detect_operation() {
  local git_dir="$1"
  if [[ -f "${git_dir}/MERGE_HEAD" ]]; then
    echo "merge"
  elif [[ -d "${git_dir}/rebase-merge" || -d "${git_dir}/rebase-apply" ]]; then
    echo "rebase"
  elif [[ -f "${git_dir}/CHERRY_PICK_HEAD" ]]; then
    echo "cherry-pick"
  elif [[ -f "${git_dir}/REVERT_HEAD" ]]; then
    echo "revert"
  elif [[ -f "${git_dir}/BISECT_LOG" ]]; then
    echo "bisect"
  fi
}

#######################################
# Print the resolve/abort commands for an in-progress operation.
# Arguments:
#   $1 - Operation name.
#######################################
print_recovery() {
  local op="$1"
  case "${op}" in
    merge)
      echo "- Resolve: \`git add <file>\` then \`git commit\`"
      echo "- Abort: \`git merge --abort\`"
      ;;
    rebase)
      echo "- Resolve: \`git add <file>\` then \`git rebase --continue\`"
      echo "- Abort: \`git rebase --abort\`"
      ;;
    cherry-pick)
      echo "- Resolve: \`git add <file>\` then \`git cherry-pick --continue\`"
      echo "- Abort: \`git cherry-pick --abort\`"
      ;;
    revert)
      echo "- Resolve: \`git add <file>\` then \`git revert --continue\`"
      echo "- Abort: \`git revert --abort\`"
      ;;
    bisect)
      echo "- Reset: \`git bisect reset\`"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Entry point. Prints the operation-state report.
#######################################
main() {
  local git_dir op
  git_dir="$(get_git_dir)"
  if [[ -z "${git_dir}" ]]; then
    err "Not inside a git work tree."
    exit 1
  fi

  for arg in "$@"; do
    case "${arg}" in
      --raw|--raw-output)
        git status --porcelain=v2
        return 0
        ;;
      -h|--help)
        echo "Usage: $0 [--raw|--raw-output]"
        return 0
        ;;
    esac
  done

  op="$(detect_operation "${git_dir}")"

  if [[ -n "${op}" ]]; then
    echo "# Operation State: IN_PROGRESS (${op})"
    echo ""
    echo "## Conflict Files"
    echo ""
    local conflicts
    conflicts="$(git diff --name-only --diff-filter=U 2>/dev/null)"
    if [[ -n "${conflicts}" ]]; then
      echo "${conflicts}"
    else
      echo "No unmerged paths (operation may be mid-edit or awaiting continue)."
    fi
    echo ""
    echo "## Recovery"
    echo ""
    print_recovery "${op}"
  else
    echo "# Operation State: CLEAN"
    echo ""
    echo "No merge, rebase, cherry-pick, revert, or bisect in progress."
  fi

  echo ""
  echo "## Staged"
  echo ""
  local staged
  staged="$(git diff --staged --name-status 2>/dev/null)"
  echo "${staged:-Nothing staged.}"
  echo ""
  echo "## Unstaged"
  echo ""
  local unstaged
  unstaged="$(git diff --name-status 2>/dev/null)"
  echo "${unstaged:-Nothing unstaged.}"
  echo ""
  echo "## Untracked"
  echo ""
  local untracked
  untracked="$(git ls-files --others --exclude-standard 2>/dev/null | head -20)"
  echo "${untracked:-None.}"
}

main "$@"