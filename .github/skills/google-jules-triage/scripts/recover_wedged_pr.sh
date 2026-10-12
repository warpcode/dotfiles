#!/usr/bin/env bash
# recover_wedged_pr.sh: Automate isolated worktree setup, empty-commit triage, and squash recovery for wedged PRs.
# Usage: recover_wedged_pr.sh <owner/repo> <pr-number> [base-branch]
# Example: recover_wedged_pr.sh warpcode/dotfiles 184 master

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <owner/repo> <pr-number> [base-branch]

Automate Workflow 6 wedged PR recovery:
  1. Fetches PR head ref into refs/remotes/origin/pr-<n>
  2. Runs detect_empty_commits.sh to verify wedged state
  3. Creates an isolated worktree at /tmp/tidy-<n> detached from origin/<base>
  4. Squashes salvageable diff into the worktree
  5. Reports merge status, conflicts (if any), and next steps

Arguments:
  <owner/repo>   Target GitHub repository slug (e.g. warpcode/dotfiles)
  <pr-number>    Pull request number
  [base-branch]  Base branch to target (default: auto-detected from PR or main)
EOF
    exit "${1:-0}"
}

if [ "$#" -lt 2 ]; then
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        usage 0
    fi
    usage 1
fi

REPO="$1"
PR_NUM="$2"
BASE="${3:-}"

# Auto-detect base branch from GitHub if not provided
if [ -z "$BASE" ]; then
    if command -v gh >/dev/null 2>&1; then
        BASE=$(gh pr view "$PR_NUM" --repo "$REPO" --json baseRefName --jq '.baseRefName' 2>/dev/null || echo "")
    fi
    if [ -z "$BASE" ]; then
        if git rev-parse --verify origin/main >/dev/null 2>&1; then
            BASE="main"
        elif git rev-parse --verify origin/master >/dev/null 2>&1; then
            BASE="master"
        else
            BASE="main"
        fi
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_DIR="/tmp/tidy-${PR_NUM}"
REF_NAME="origin/pr-${PR_NUM}"

echo "=== Wedged PR Recovery: $REPO #$PR_NUM (Base: $BASE) ==="

# 1. Fetch PR ref
echo "-> Fetching pull/$PR_NUM/head to refs/remotes/$REF_NAME..."
git fetch origin "pull/$PR_NUM/head:refs/remotes/$REF_NAME" --force

# 2. Count empty commits
echo "-> Checking for empty commit loops..."
if [ -x "$SCRIPT_DIR/detect_empty_commits.sh" ]; then
    set +e
    "$SCRIPT_DIR/detect_empty_commits.sh" "origin/$BASE" "$REF_NAME"
    STATUS=$?
    set -e
    if [ "$STATUS" -eq 2 ]; then
        echo "Confirmed: Branch is wedged with >=2 empty commits."
    elif [ "$STATUS" -eq 1 ]; then
        echo "Notice: Branch contains 1 empty commit."
    else
        echo "Notice: No empty commits detected; proceeding with squash recovery."
    fi
fi

# 3. Worktree isolation
if [ -d "$WORKTREE_DIR" ]; then
    echo "-> Cleaning existing worktree at $WORKTREE_DIR..."
    git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || rm -rf "$WORKTREE_DIR"
fi

echo "-> Creating isolated worktree at $WORKTREE_DIR (detached from origin/$BASE)..."
git worktree add --detach "$WORKTREE_DIR" "origin/$BASE"

# 4. Squash merge
echo "-> Squashing changes from $REF_NAME into $WORKTREE_DIR..."
set +e
git -C "$WORKTREE_DIR" merge --squash "$REF_NAME"
MERGE_EXIT=$?
set -e

echo ""
if [ "$MERGE_EXIT" -ne 0 ]; then
    echo "⚠️ Merge conflicts detected during squash merge."
    echo "Conflicted files in $WORKTREE_DIR:"
    git -C "$WORKTREE_DIR" status --short | grep -E '^UU|^AA|^DU|^UD' || true
    echo ""
    echo "Next steps:"
    echo "  1. cd $WORKTREE_DIR"
    echo "  2. Resolve conflicts (keep both sides' tests if independent)"
    echo "  3. Run validation/test suite"
    echo "  4. Commit once: git commit -m '...'"
else
    echo "✅ Squash merge applied cleanly to $WORKTREE_DIR!"
    echo "Staged changes summary:"
    git -C "$WORKTREE_DIR" status --short
    echo ""
    echo "Next steps:"
    echo "  1. cd $WORKTREE_DIR"
    echo "  2. Run repository verification (e.g. ./validate.sh or test suite)"
    echo "  3. Commit once: git commit -m '...'"
fi
EOF
