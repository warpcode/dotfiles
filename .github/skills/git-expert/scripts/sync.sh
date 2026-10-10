#!/usr/bin/env bash
# sync.sh
# Safely synchronizes the current branch with remote changes via fetch and rebase.
# Preserves unstaged/tracked modifications via temporary git stash,
# leaves untracked files completely untouched, and respects non-interactive rules.

set -euo pipefail
export PAGER=cat

show_help() {
  cat <<'EOF'
Usage:
  sync.sh [options] [remote] [branch]

Arguments:
  remote               Remote repository name (default: tracking remote or 'origin')
  branch               Branch name to sync against (default: tracking branch or 'master')

Options:
  -h, --help           Show this help message and exit
  -n, --dry-run        Report divergence and status without mutating git state
  --raw                Output porcelain status summary only

Description:
  1. Validates git repo and working tree state.
  2. Identifies remote and upstream branch.
  3. Fetches latest commits from remote.
  4. Checks divergence (ahead/behind commit counts).
  5. Stashes modified tracked files safely (leaving untracked files untouched).
  6. Rebases current branch non-interactively onto fetched remote target.
  7. Restores stashed changes if any were stashed.
  8. Emits a clean Markdown summary.
EOF
}

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

DRY_RUN=0
RAW_OUTPUT=0
REMOTE_ARG=""
BRANCH_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --raw)
      RAW_OUTPUT=1
      shift
      ;;
    *)
      if [[ -z "$REMOTE_ARG" ]]; then
        REMOTE_ARG="$1"
        shift
      elif [[ -z "$BRANCH_ARG" ]]; then
        BRANCH_ARG="$1"
        shift
      else
        echo "Error: Unknown argument '$1'" >&2
        show_help >&2
        exit 1
      fi
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  err "git is not installed or not in PATH."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  err "Not inside a git work tree."
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || true)"
if [[ -z "$CURRENT_BRANCH" ]]; then
  err "Detached HEAD detected. Please switch to a branch before syncing."
  exit 1
fi

UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"

if [[ -n "$REMOTE_ARG" ]]; then
  REMOTE="$REMOTE_ARG"
elif [[ -n "$UPSTREAM" ]]; then
  REMOTE="${UPSTREAM%%/*}"
else
  REMOTE="origin"
fi

if [[ -n "$BRANCH_ARG" ]]; then
  TARGET_BRANCH="$BRANCH_ARG"
elif [[ -n "$UPSTREAM" ]]; then
  TARGET_BRANCH="${UPSTREAM#*/}"
else
  # Default to remote HEAD symbol or master/main
  REMOTE_HEAD="$(git symbolic-ref "refs/remotes/${REMOTE}/HEAD" 2>/dev/null || true)"
  if [[ -n "$REMOTE_HEAD" ]]; then
    TARGET_BRANCH="${REMOTE_HEAD#refs/remotes/"${REMOTE}"/}"
  elif git show-ref --verify --quiet "refs/remotes/${REMOTE}/master" 2>/dev/null; then
    TARGET_BRANCH="master"
  elif git show-ref --verify --quiet "refs/remotes/${REMOTE}/main" 2>/dev/null; then
    TARGET_BRANCH="main"
  else
    TARGET_BRANCH="master"
  fi
fi

REMOTE_REF="${REMOTE}/${TARGET_BRANCH}"

if [[ "$RAW_OUTPUT" -eq 1 ]]; then
  git status --porcelain=v2 --branch
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "# Git Sync (Dry Run)"
  echo "- Current branch: \`$CURRENT_BRANCH\`"
  echo "- Target: \`$REMOTE_REF\`"
  git fetch "$REMOTE" "$TARGET_BRANCH" --quiet
  AHEAD="$(git log "${REMOTE_REF}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')"
  BEHIND="$(git log "HEAD..${REMOTE_REF}" --oneline 2>/dev/null | wc -l | tr -d ' ')"
  echo "- Commits ahead: $AHEAD"
  echo "- Commits behind: $BEHIND"
  exit 0
fi

# Fetch remote
git fetch "$REMOTE" "$TARGET_BRANCH" --quiet

# Check for modified tracked files
HAS_CHANGES=0
if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
  HAS_CHANGES=1
fi

STASHED=0
if [[ "$HAS_CHANGES" -eq 1 ]]; then
  STASH_MSG="git-expert-sync-$(date +%s)"
  # Do NOT use -u or -a: leave untracked files completely untouched!
  if git stash push -m "$STASH_MSG" --quiet; then
    # Verify stash was created
    LATEST_STASH_MSG="$(git stash list -n 1 2>/dev/null || true)"
    if [[ "$LATEST_STASH_MSG" == *"$STASH_MSG"* ]]; then
      STASHED=1
    fi
  fi
fi

# Rebase non-interactively
REBASE_ERR=""
if ! git -c core.editor=true rebase "$REMOTE_REF"; then
  REBASE_ERR="Rebase failed or encountered conflicts."
fi

# Pop stash if created
POP_ERR=""
if [[ "$STASHED" -eq 1 ]]; then
  if ! git stash pop --quiet; then
    POP_ERR="Stash restore encountered merge conflicts. Working tree has conflict markers."
  fi
fi

echo "# Git Sync Summary"
echo ""
echo "| Property | Value |"
echo "|---|---|"
echo "| Branch | \`$CURRENT_BRANCH\` |"
echo "| Synced Against | \`$REMOTE_REF\` |"
echo "| Tracked Changes Stashed | $([[ "$STASHED" -eq 1 ]] && echo "Yes (restored)" || echo "None") |"
echo "| Untracked Files | Untouched |"

if [[ -n "$REBASE_ERR" ]]; then
  echo ""
  echo "⚠️ **$REBASE_ERR**"
  echo "Run \`git rebase --abort\` to cancel or resolve conflicts and run \`git rebase --continue\`."
  exit 1
fi

if [[ -n "$POP_ERR" ]]; then
  echo ""
  echo "⚠️ **$POP_ERR**"
  exit 1
fi

AHEAD="$(git log "${REMOTE_REF}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')"
MODIFIED_COUNT="$(git status --porcelain 2>/dev/null | grep -vc '^??' || true)"
UNTRACKED_COUNT="$(git status --porcelain 2>/dev/null | grep -c '^??' || true)"
echo "| Commits Ahead | $AHEAD |"
echo "| Working Tree | ${MODIFIED_COUNT} modified, ${UNTRACKED_COUNT} untracked |"

if [[ "$AHEAD" -gt 0 ]]; then
  echo ""
  echo "**Commits ahead of \`${REMOTE_REF}\`:**"
  git log "${REMOTE_REF}..HEAD" --oneline -n 10 | sed 's/^/- /'
fi
echo ""
echo "Successfully rebased \`$CURRENT_BRANCH\` onto \`$REMOTE_REF\`."
