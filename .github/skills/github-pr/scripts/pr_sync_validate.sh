#!/usr/bin/env bash
# pr_sync_validate.sh - sync a PR branch with its base by MERGE (never rebase/force-push),
# validate in an isolated worktree, and optionally push. Non-interactive.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: pr_sync_validate.sh <pr> --repo owner/name [options]

Phases (re-run the same command to move to the next phase):
  1. start    (default)  create /tmp worktree, `git merge origin/<base>`.
                         Exit 0 = clean merge, validated. Exit 2 = conflicts: lists the
                         conflicted files and leaves the worktree for manual resolution.
  2. --continue          after you resolved + `git add`-ed the conflicts: finish the merge
                         with GIT_EDITOR=true `git merge --continue`, then validate.

Options:
  --repo OWNER/NAME   repository (combined form)                    [required]
  --repo-dir DIR      local clone to attach the worktree to         [default: .]
  --wt DIR            worktree path                                 [default: /tmp/wt-pr<N>]
  --validate CMD      validation command run in the worktree        [default: ./validate.sh]
  --no-validate       skip validation
  --push              standard `git push` after a validated merge (never forced)
  --cleanup           remove the worktree afterwards (only after success)
  --continue          finish an in-progress merge (phase 2)
  --dry-run           print what would run; mutate nothing
  -h, --help          show this help

Refuses Jules-owned PR branches (start a new Jules session instead).
Exit codes: 0 ok | 1 usage/setup failure | 2 merge conflicts | 3 validation failed | 4 push failed
EOF
}

PR="" REPO="" REPO_DIR="." WT="" VALIDATE="./validate.sh"
DO_VALIDATE=1 PUSH=0 CLEANUP=0 CONTINUE=0 DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:?--repo needs a value}"; shift 2 ;;
    --repo-dir) REPO_DIR="${2:?--repo-dir needs a value}"; shift 2 ;;
    --wt) WT="${2:?--wt needs a value}"; shift 2 ;;
    --validate) VALIDATE="${2:?--validate needs a value}"; shift 2 ;;
    --no-validate) DO_VALIDATE=0; shift ;;
    --push) PUSH=1; shift ;;
    --cleanup) CLEANUP=1; shift ;;
    --continue) CONTINUE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "error: unknown flag $1" >&2; usage >&2; exit 1 ;;
    *) PR="$1"; shift ;;
  esac
done

[ -n "$PR" ] && [ -n "$REPO" ] || { echo "error: <pr> and --repo are required" >&2; usage >&2; exit 1; }
case "$PR" in *[!0-9]*) echo "error: <pr> must be a number" >&2; exit 1 ;; esac
WT="${WT:-/tmp/wt-pr$PR}"

run() { if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi; }

# Single metadata call.
META="$(gh pr view "$PR" --repo "$REPO" --json headRefName,baseRefName,author,state \
  --jq '[.headRefName,.baseRefName,.author.login,.state]|@tsv')"
IFS=$'\t' read -r HEAD BASE AUTHOR STATE <<<"$META"

[ "$STATE" = "OPEN" ] || { echo "error: PR #$PR is $STATE, not OPEN" >&2; exit 1; }
case "$AUTHOR" in
  *jules*|*Jules*) echo "error: PR #$PR is Jules-owned ($AUTHOR); do not push to its branch. Start a new Jules session." >&2; exit 1 ;;
esac
echo "PR #$PR: $HEAD <- merge origin/$BASE (author: $AUTHOR, worktree: $WT)"

if [ "$CONTINUE" = 0 ]; then
  [ ! -e "$WT" ] || { echo "error: $WT already exists (use --continue, or remove it after checking it is not a symlink)" >&2; exit 1; }
  run git -C "$REPO_DIR" fetch origin "$BASE" "$HEAD"
  run git -C "$REPO_DIR" worktree add "$WT" -B "$HEAD" "origin/$HEAD"
  if [ "$DRY" = 0 ]; then
    if ! git -C "$WT" -c core.editor=true merge --no-edit "origin/$BASE"; then
      echo "CONFLICTS in PR #$PR - resolve, 'git add', then re-run with --continue:" >&2
      git -C "$WT" diff --name-only --diff-filter=U >&2
      exit 2
    fi
  else
    echo "[dry-run] git -C $WT -c core.editor=true merge --no-edit origin/$BASE"
  fi
else
  [ -d "$WT" ] || { echo "error: worktree $WT not found" >&2; exit 1; }
  if [ "$DRY" = 0 ]; then
    if [ -n "$(git -C "$WT" diff --name-only --diff-filter=U)" ]; then
      echo "error: unresolved conflicts remain:" >&2
      git -C "$WT" diff --name-only --diff-filter=U >&2
      exit 2
    fi
    # Merge may already be concluded; only continue when one is in progress.
    if git -C "$WT" rev-parse -q --verify MERGE_HEAD >/dev/null; then
      GIT_EDITOR=true git -C "$WT" merge --continue
    fi
  else
    echo "[dry-run] GIT_EDITOR=true git -C $WT merge --continue"
  fi
fi

if [ "$DO_VALIDATE" = 1 ]; then
  echo "Validating: $VALIDATE (in $WT)"
  if [ "$DRY" = 1 ]; then
    echo "[dry-run] (cd $WT && $VALIDATE)"
  elif ! (cd "$WT" && bash -c "$VALIDATE"); then
    echo "error: validation failed in $WT (left in place)" >&2
    exit 3
  fi
fi

if [ "$PUSH" = 1 ]; then
  run git -C "$WT" push origin "HEAD:$HEAD" || { echo "error: push failed" >&2; exit 4; }
fi

if [ "$CLEANUP" = 1 ]; then
  if [ -L "$WT" ]; then echo "error: $WT is a symlink; not removing" >&2; exit 1; fi
  run git -C "$REPO_DIR" worktree remove "$WT"
fi
echo "OK: PR #$PR synced and validated."
