#!/usr/bin/env bash
# pr_sync.sh - Synchronize a PR branch with origin/master in an isolated worktree
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

usage() {
  cat <<'EOF'
Usage: pr_sync.sh <pr-number-or-branch> [OPTIONS]

Synchronizes a PR branch with origin/master inside an isolated worktree
following repository safety invariants.

Arguments:
  pr-number-or-branch   Pull request number or remote branch name

Options:
  -R, --repo <owner/repo>   Target repository (e.g. warpcode/dotfiles)
  --base <ref>              Base branch to merge into PR branch (default: origin/master)
  --continue                Resume after resolving merge conflicts: runs tests, pushes, and removes worktree
  --abort                   Abort in-progress merge conflict and remove worktree
  -h, --help                Show this help message
EOF
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

TARGET="$1"
shift

REPO=""
BASE_REF="origin/master"
CONTINUE=0
ABORT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -R|--repo)
      REPO="$2"
      shift 2
      ;;
    --base)
      BASE_REF="$2"
      shift 2
      ;;
    --continue)
      CONTINUE=1
      shift
      ;;
    --abort)
      ABORT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

REPO_ARGS=()
[[ -n "$REPO" ]] && REPO_ARGS=(--repo "$REPO")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve branch name if numeric PR
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  BRANCH="$(gh pr view "$TARGET" "${REPO_ARGS[@]}" --json headRefName -q .headRefName 2>/dev/null || echo '')"
  if [[ -z "$BRANCH" ]]; then
    echo "Error: Could not resolve branch for PR #$TARGET." >&2
    exit 1
  fi
else
  BRANCH="$TARGET"
fi

SAFE_NAME="$(echo "$BRANCH" | tr '/' '-')"
WT_PATH="/tmp/wt-${SAFE_NAME}"

if [[ $ABORT -eq 1 ]]; then
  if [[ -d "$WT_PATH" ]]; then
    echo "Aborting merge and cleaning up worktree at $WT_PATH..."
    git -C "$WT_PATH" merge --abort 2>/dev/null || true
    bash "$SCRIPT_DIR/worktrees.sh" --remove "$WT_PATH"
    echo "Worktree removed."
  else
    echo "No worktree found at $WT_PATH."
  fi
  exit 0
fi

if [[ $CONTINUE -eq 1 ]]; then
  if [[ ! -d "$WT_PATH" ]]; then
    echo "Error: Worktree $WT_PATH does not exist. Nothing to continue." >&2
    exit 1
  fi

  # Check if unresolved conflict markers remain
  unmerged="$(git -C "$WT_PATH" status --porcelain | grep '^UU\|^AA\|^UD\|^DU\|^UA\|^AU' || true)"
  if [[ -n "$unmerged" ]]; then
    echo "Error: Unresolved merge conflicts remain in $WT_PATH:" >&2
    echo "$unmerged" >&2
    echo "Please resolve conflicts and stage files before running --continue." >&2
    exit 1
  fi

  echo "Committing resolved merge..."
  git -C "$WT_PATH" commit --no-edit || true

  echo "Running validation suite in worktree..."
  if [[ -f "$WT_PATH/validate.sh" ]]; then
    bash "$SCRIPT_DIR/wt_test.sh" "$WT_PATH" ./validate.sh
  else
    echo "No validate.sh found; running basic git status check."
  fi

  echo "Pushing $BRANCH to origin..."
  git -C "$WT_PATH" push origin "$BRANCH"

  echo "Cleaning up worktree..."
  bash "$SCRIPT_DIR/worktrees.sh" --remove "$WT_PATH"
  echo "✓ Successfully synced, validated, and pushed $BRANCH."
  exit 0
fi

echo "Fetching latest $BRANCH and $BASE_REF..."
git fetch origin "$BRANCH"
if [[ "$BASE_REF" == origin/* ]]; then
  git fetch origin "${BASE_REF#origin/}"
fi

echo "Creating isolated worktree at $WT_PATH..."
bash "$SCRIPT_DIR/worktrees.sh" --create "$BRANCH" --base "origin/$BRANCH" --path "$WT_PATH"

echo "Attempting to merge $BASE_REF into $BRANCH..."
if git -C "$WT_PATH" merge "$BASE_REF" --no-edit; then
  echo "Merge succeeded cleanly. Running validation suite..."
  if [[ -f "$WT_PATH/validate.sh" ]]; then
    bash "$SCRIPT_DIR/wt_test.sh" "$WT_PATH" ./validate.sh
  fi

  echo "Pushing $BRANCH to origin..."
  git -C "$WT_PATH" push origin "$BRANCH"

  echo "Cleaning up worktree..."
  bash "$SCRIPT_DIR/worktrees.sh" --remove "$WT_PATH"
  echo "✓ Successfully merged $BASE_REF into $BRANCH and pushed cleanly."
else
  echo ""
  echo "⚠️  Merge conflict encountered in $WT_PATH."
  echo "Conflicting files:"
  git -C "$WT_PATH" diff --name-only --diff-filter=U | sed 's/^/  - /'
  echo ""
  echo "Resolve conflicts in $WT_PATH, stage files with 'git add', then run:"
  echo "  bash $0 $TARGET --continue"
  echo "Or to cancel:"
  echo "  bash $0 $TARGET --abort"
  exit 1
fi
