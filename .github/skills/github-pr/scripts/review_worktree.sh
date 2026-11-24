#!/usr/bin/env bash
# Create, list and destroy throwaway audit worktrees with one naming scheme.
#
# Why this exists: a PR audit needs an isolated checkout of the PR head (and
# often of the base branch, to tell "this PR introduced an untested branch"
# from "already untested repo-wide"). Done by hand that produced three
# separate failure modes across real sessions:
#   * inconsistent names for the same role -- wt208 vs wt-main vs wt-base vs
#     w200base all meant "the base branch" in one session;
#   * leaked worktrees, because creation and removal were unrelated commands
#     and a failure between them left the checkout on disk;
#   * a `git worktree remove` chain that had to be retyped per PR.
# This script gives each role a fixed path, records what it created in a
# registry, and tears the whole set down in one call.
#
# Usage:
#   review_worktree.sh add   --pr N [--role head|base|merge] [--ref REF]
#   review_worktree.sh add   --pr N --role head --ref origin/pr-N
#   review_worktree.sh rm    --pr N [--role head|base|merge] [--force]
#   review_worktree.sh rm    --pr N --all-roles
#   review_worktree.sh rm    --all-prs
#   review_worktree.sh list  [--pr N]
#   review_worktree.sh exec   --pr N --role head -- <command...>
#
#   --pr N        pull request number (part of the path)
#   --role ROLE   head = the PR head (default); base = the default branch;
#                 merge = a scratch integration checkout
#   --ref REF     ref to check out       [default: origin/pr-<N> for head,
#                                         the default branch for base/merge]
#   --path DIR    override the worktree path
#   --root DIR    parent directory       [default: /tmp/opencode/wt]
#   --force       pass --force to git worktree remove
#   --keep        do not remove even on success (for manual poking)
#   --all-roles   with rm/list, act on every role of this PR
#   --all-prs     operate on every worktree this script created
#   -h, --help    show this help
#
# Prints the absolute worktree path on stdout for `add` and `exec`, so it
# composes:  cd "$(review_worktree.sh add --pr 213 --role head)"
#
# Registry: $WT_ROOT/.registry (one "<pr> <role> <path>" row per worktree).
# Removals are idempotent; `rm --all-prs` is safe to run at any time.
#
# Exit codes: 0 ok, 1 usage error, 2 git refused (e.g. ref does not exist).

set -euo pipefail

WT_ROOT="${WT_ROOT:-/tmp/opencode/wt}"
REGISTRY="$WT_ROOT/.registry"

die() { printf 'review_worktree: %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,34p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

cmd=""; pr=""; role="head"; role_given=0; ref=""; path=""; force=0; keep=0; all_prs=0; all_roles=0
declare -a exec_cmd=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    add|rm|list|exec) cmd="$1"; shift ;;
    --pr)      pr="${2:-}"; shift 2 ;;
    --role)    role="${2:-}"; role_given=1; shift 2 ;;
    --ref)     ref="${2:-}"; shift 2 ;;
    --path)    path="${2:-}"; shift 2 ;;
    --root)    WT_ROOT="${2:-}"; shift 2 ;;
    --force)   force=1; shift ;;
    --keep)    keep=1; shift ;;
    --all-roles) all_roles=1; shift ;;
    --all-prs) all_prs=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --)        shift; exec_cmd=("$@"); break ;;
    *)         die "unknown argument: $1" ;;
  esac
done
REGISTRY="$WT_ROOT/.registry"

[[ -n "$cmd" ]] || { usage; exit 1; }
case "$role" in head|base|merge) ;; *) die "invalid --role '$role' (head|base|merge)" ;; esac

default_base_ref() {
  for candidate in origin/main origin/master; do
    if git rev-parse --verify -q "$candidate" >/dev/null; then
      printf '%s' "$candidate"; return 0
    fi
  done
  printf 'origin/main'
}

# Path for a role. Fixed per (pr, role) so a re-add replaces rather than
# silently creating a second checkout under a new ad-hoc name.
path_for() {
  local p="$1" r="$2"
  [[ -n "$path" ]] && { printf '%s' "$path"; return; }
  printf '%s/pr%s-%s' "$WT_ROOT" "$p" "$r"
}

registry_rows() {
  [[ -f "$REGISTRY" ]] || return 0
  cat "$REGISTRY"
}

registry_add() {
  mkdir -p "$WT_ROOT"
  touch "$REGISTRY"
  grep -vxF "$1 $2 $3" "$REGISTRY" > "$REGISTRY.tmp" 2>/dev/null || true
  printf '%s %s %s\n' "$1" "$2" "$3" >> "$REGISTRY.tmp"
  mv "$REGISTRY.tmp" "$REGISTRY"
}

registry_del() {
  [[ -f "$REGISTRY" ]] || return 0
  grep -vxF "$1 $2 $3" "$REGISTRY" > "$REGISTRY.tmp" 2>/dev/null || true
  mv "$REGISTRY.tmp" "$REGISTRY"
}

do_add() {
  [[ -n "$pr" ]] || die "--pr is required for add"

  if [[ -z "$ref" ]]; then
    if [[ "$role" == "head" ]]; then
      ref="origin/pr-${pr}"
      # Fully qualify the destination. A short destination like `origin/pr-N`
      # makes git create a LOCAL BRANCH refs/heads/origin/pr-N, not the
      # remote-tracking ref -- and once the real refs/remotes/origin/pr-N
      # appears (any documented fetch creates it) `origin/pr-N` is ambiguous and
      # every `git rev-parse origin/pr-N` downstream fails.
      git fetch -q origin "+refs/pull/${pr}/head:refs/remotes/${ref}" --force \
        || die "could not fetch refs/pull/${pr}/head (is #$pr still open?)"
    else
      ref="$(default_base_ref)"
    fi
  fi

  git rev-parse --verify -q "$ref" >/dev/null \
    || die "ref '$ref' does not exist locally (fetch it first, or pass --ref)"

  local target; target="$(path_for "$pr" "$role")"

  if [[ -e "$target" ]]; then
    # Reuse rather than duplicate: the previous audit's checkout may still be
    # there, and a second name for the same role is the failure mode this
    # script exists to prevent.
    if [[ -d "$target" ]]; then
      git -C "$target" checkout -q --detach "$ref" 2>/dev/null \
        || die "$target exists but is not a usable worktree; remove it manually"
      registry_add "$pr" "$role" "$target"
      printf '%s\n' "$target"
      return 0
    fi
    die "$target exists and is not a directory"
  fi

  git worktree add --detach "$target" "$ref" >/dev/null 2>&1 \
    || die "git worktree add failed for $target at $ref"
  registry_add "$pr" "$role" "$target"
  printf '%s\n' "$target"
}

do_rm() {
  local removed=0
  local failed=0
  local -a targets=()

  if [[ "$all_prs" -eq 1 ]]; then
    while read -r r_pr r_role r_path; do
      [[ -n "$r_path" ]] || continue
      targets+=("$r_path")
    done < <(registry_rows)
  elif [[ "$all_roles" -eq 1 ]]; then
    [[ -n "$pr" ]] || die "--pr is required for rm --all-roles"
    while read -r r_pr r_role r_path; do
      [[ "$r_pr" == "$pr" ]] || continue
      [[ -n "$r_path" ]] || continue
      targets+=("$r_path")
    done < <(registry_rows)
    # Fall back to the conventional paths when the registry is empty (a
    # worktree created by hand, or a registry that was wiped).
    if [[ ${#targets[@]} -eq 0 ]]; then
      targets+=("$(path_for "$pr" head)" "$(path_for "$pr" base)" "$(path_for "$pr" merge)")
    fi
  else
    [[ -n "$pr" ]] || die "--pr is required for rm (or pass --all-prs)"
    local target; target="$(path_for "$pr" "$role")"
    targets+=("$target")
  fi

  for t in "${targets[@]}"; do
    [[ -n "$t" ]] || continue
    if [[ -e "$t" ]]; then
      local -a rm_args=(worktree remove)
      [[ "$force" -eq 1 ]] && rm_args+=(--force)
      if git "${rm_args[@]}" "$t" >/dev/null 2>&1; then
        printf 'removed %s\n' "$t" >&2
        removed=1
      elif [[ ! -e "$t" ]]; then
        printf 'already gone %s\n' "$t" >&2
      else
        printf 'FAILED to remove %s (use --force if it has local changes)\n' "$t" >&2
        failed=1
      fi
    else
      # Registry row without a directory: prune the bookkeeping, not a real leak.
      registry_del "$pr" "$role" "$t"
    fi
  done

  # Drop rows whose directory is gone, including rows for other PRs.
  if [[ -f "$REGISTRY" ]]; then
    : > "$REGISTRY.new"
    while read -r r_pr r_role r_path; do
      [[ -n "$r_path" ]] || continue
      [[ -e "$r_path" ]] && printf '%s %s %s\n' "$r_pr" "$r_role" "$r_path" >> "$REGISTRY.new"
    done < <(registry_rows)
    mv "$REGISTRY.new" "$REGISTRY"
  fi
  git worktree prune

  # A leaked worktree must not pass as success: a caller cleaning up after an
  # audit would report "done" while the checkout is still on disk.
  [[ "$failed" -eq 0 ]] || return 2
  [[ "$removed" -eq 1 ]] || printf 'nothing to remove\n' >&2
}

do_list() {
  # With an explicit --role, print that role's conventional path (usable in a
  # command substitution). Otherwise list what actually exists.
  if [[ "$all_roles" -eq 0 && "$all_prs" -eq 0 && -n "$pr" && "$role_given" -eq 1 ]]; then
    path_for "$pr" "$role"
    return 0
  fi
  if [[ -n "$pr" || "$all_prs" -eq 1 || -z "$pr" ]]; then
    if ! registry_rows | grep -q .; then
      printf 'no audit worktrees registered under %s\n' "$WT_ROOT"
      return 0
    fi
    printf '%-6s %-7s %s\n' PR ROLE PATH
    while read -r r_pr r_role r_path; do
      [[ -n "$r_path" ]] || continue
      [[ -n "$pr" && "$r_pr" != "$pr" ]] && continue
      [[ -e "$r_path" ]] || continue
      printf '%-6s %-7s %s\n' "$r_pr" "$r_role" "$r_path"
    done < <(registry_rows)
    return 0
  fi
}

do_exec() {
  [[ ${#exec_cmd[@]} -gt 0 ]] || die "exec requires a command after --"
  [[ -n "$pr" ]] || die "--pr is required for exec"
  local target; target="$(path_for "$pr" "$role")"
  if [[ ! -d "$target" ]]; then
    target="$(do_add)"
  fi
  ( cd "$target" && "${exec_cmd[@]}" )
}

case "$cmd" in
  add)  do_add ;;
  rm)   do_rm ;;
  list) do_list ;;
  exec) do_exec ;;
  *)    die "unknown command '$cmd'" ;;
esac

# `keep` is honoured by the caller (mutation_check.sh) rather than here: the
# worktree must outlive this process for the command that uses it.
if [[ "$cmd" == "add" && "$keep" -eq 1 ]]; then
  :
fi