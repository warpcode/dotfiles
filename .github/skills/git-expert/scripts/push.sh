#!/usr/bin/env bash
# push.sh
# Safely pushes local commits to upstream remote with preflight verification and Markdown summary.

set -euo pipefail
export PAGER=cat

show_help() {
  cat <<'EOF'
Usage:
  push.sh [options] [remote] [branch]

Arguments:
  remote                 Remote repository name (default: tracking remote or 'origin')
  branch                 Branch name to push to (default: tracking branch or current branch)

Options:
  -h, --help             Show this help message and exit
  -n, --dry-run          Report commits that would be pushed without pushing
  --force-with-lease     Allow safe force push with lease (requires explicit flag)
  --raw                  Output porcelain branch status summary only

Description:
  1. Validates git repo and verifies not in detached HEAD.
  2. Resolves remote and target branch.
  3. Checks ahead commit count.
  4. If ahead > 0, lists commits to be pushed and pushes them cleanly.
  5. Emits a concise Markdown summary of the push result.
EOF
}

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

DRY_RUN=0
RAW_OUTPUT=0
FORCE_FLAG=""
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
    --force-with-lease)
      FORCE_FLAG="--force-with-lease"
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
  err "Detached HEAD detected. Please checkout a branch before pushing."
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
  TARGET_BRANCH="$CURRENT_BRANCH"
fi

REMOTE_REF="${REMOTE}/${TARGET_BRANCH}"

if [[ "$RAW_OUTPUT" -eq 1 ]]; then
  git status --porcelain=v2 --branch
  exit 0
fi

AHEAD="$(git log "${REMOTE_REF}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ' || true)"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "# Git Push (Dry Run)"
  echo ""
  echo "| Property | Value |"
  echo "|---|---|"
  echo "| Current Branch | \`$CURRENT_BRANCH\` |"
  echo "| Destination | \`$REMOTE_REF\` |"
  echo "| Commits to Push | $AHEAD |"
  if [[ "$AHEAD" -gt 0 ]]; then
    echo ""
    echo "**Commits to be pushed:**"
    git log "${REMOTE_REF}..HEAD" --oneline | sed 's/^/- /'
  fi
  exit 0
fi

if [[ "$AHEAD" -eq 0 ]]; then
  echo "# Git Push"
  echo ""
  echo "Branch \`$CURRENT_BRANCH\` is already up to date with \`$REMOTE_REF\`. Nothing to push."
  exit 0
fi

echo "# Git Push Summary"
echo ""
echo "| Property | Value |"
echo "|---|---|"
echo "| Branch | \`$CURRENT_BRANCH\` |"
echo "| Destination | \`$REMOTE_REF\` |"
echo "| Commits Pushed | $AHEAD |"
echo ""
echo "**Pushed Commits:**"
git log "${REMOTE_REF}..HEAD" --oneline | sed 's/^/- /'
echo ""

PUSH_ARGS=()
if [[ -n "$FORCE_FLAG" ]]; then
  PUSH_ARGS+=("$FORCE_FLAG")
fi
PUSH_ARGS+=("$REMOTE" "${CURRENT_BRANCH}:${TARGET_BRANCH}")

git push "${PUSH_ARGS[@]}"

echo ""
echo "Successfully pushed \`$CURRENT_BRANCH\` to \`$REMOTE_REF\`."
