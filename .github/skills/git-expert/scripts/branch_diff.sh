#!/usr/bin/env bash
#
# Compare the current branch against its base branch (auto-detected default
# branch or explicit --base <ref>). Displays divergence summary, commit list,
# and changed files summary, with optional triage diff.
#
# Usage: ./branch_diff.sh [--base <ref>] [--diff] [--raw|--raw-output]

set -euo pipefail
export PAGER=cat

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

print_usage() {
  cat <<'EOF'
Usage: ./branch_diff.sh [options]

Options:
  --base <ref>       Base branch or reference to compare against (e.g. origin/main, main)
  --diff             Run git-diff-triage.py on <base>...HEAD
  --raw, --raw-output Output raw commit list and stat (no markdown formatting)
  -h, --help         Show this help message
EOF
}

#######################################
# Get the current branch name.
# Outputs:
#   Current branch name, or "DETACHED HEAD (<sha>)".
#######################################
get_current_branch() {
  local branch head_sha
  branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ -n "${branch}" ]]; then
    echo "${branch}"
  else
    head_sha="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    echo "DETACHED HEAD (${head_sha})"
  fi
}

#######################################
# Detect the base branch dynamically.
# Outputs:
#   Base reference name, or empty string if not found.
#######################################
detect_base_branch() {
  local origin_head
  origin_head="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "${origin_head}" ]] && git rev-parse --verify "${origin_head}" >/dev/null 2>&1; then
    echo "${origin_head}"
    return 0
  fi

  local candidate
  for candidate in "origin/main" "origin/master" "main" "master"; do
    if git rev-parse --verify "${candidate}" >/dev/null 2>&1; then
      echo "${candidate}"
      return 0
    fi
  done

  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    err "Not inside a git work tree."
    exit 1
  fi

  local base_ref=""
  local show_diff="no"
  local raw_mode="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)
        if [[ $# -lt 2 || -z "$2" ]]; then
          err "Option --base requires a non-empty argument."
          exit 1
        fi
        base_ref="$2"
        shift 2
        ;;
      --base=*)
        base_ref="${1#*=}"
        if [[ -z "${base_ref}" ]]; then
          err "Option --base requires a non-empty argument."
          exit 1
        fi
        shift
        ;;
      --diff)
        show_diff="yes"
        shift
        ;;
      --raw|--raw-output)
        raw_mode="yes"
        shift
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        print_usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "${base_ref}" ]]; then
    base_ref="$(detect_base_branch)"
    if [[ -z "${base_ref}" ]]; then
      err "Could not auto-detect base branch (tried origin/HEAD, origin/main, origin/master, main, master). Specify one with --base <ref>."
      exit 1
    fi
  else
    if ! git rev-parse --verify "${base_ref}" >/dev/null 2>&1; then
      err "Base reference '${base_ref}' not found."
      exit 1
    fi
  fi

  local script_dir diff_triage_script
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  diff_triage_script="${script_dir}/git-diff-triage.py"

  # Raw mode output
  if [[ "${raw_mode}" == "yes" ]]; then
    git log "${base_ref}..HEAD" --oneline 2>/dev/null || true
    echo ""
    git diff --stat "${base_ref}...HEAD" 2>/dev/null || true
    if [[ "${show_diff}" == "yes" ]]; then
      echo ""
      if [[ -f "${diff_triage_script}" ]]; then
        python3 "${diff_triage_script}" --raw -- "${base_ref}...HEAD"
      else
        git diff "${base_ref}...HEAD"
      fi
    fi
    exit 0
  fi

  local current_branch merge_base merge_base_short ahead_behind behind ahead
  current_branch="$(get_current_branch)"
  merge_base="$(git merge-base "${base_ref}" HEAD 2>/dev/null || true)"

  if [[ -n "${merge_base}" ]]; then
    merge_base_short="$(git rev-parse --short "${merge_base}" 2>/dev/null || echo "${merge_base}")"
    ahead_behind="$(git rev-list --left-right --count "${base_ref}...HEAD" 2>/dev/null || echo "0 0")"
    behind="$(awk '{print $1}' <<< "${ahead_behind}")"
    ahead="$(awk '{print $2}' <<< "${ahead_behind}")"
  else
    merge_base_short="None (no common ancestor)"
    behind="—"
    ahead="—"
  fi

  echo "# Branch Diff: ${current_branch} vs ${base_ref}"
  echo ""
  echo "| Detail | Value |"
  echo "|--------|-------|"
  echo "| Current Branch | ${current_branch} |"
  echo "| Base Reference | ${base_ref} |"
  echo "| Merge Base | ${merge_base_short} |"
  echo "| Commits Ahead | ${ahead} |"
  echo "| Commits Behind | ${behind} |"
  echo ""

  # ── Commits ───────────────────────────────────────────────────────────
  echo "## Commits (${ahead})"
  echo ""
  local commits
  commits="$(git log "${base_ref}..HEAD" --oneline 2>/dev/null || true)"
  if [[ -n "${commits}" ]]; then
    echo "${commits}"
  else
    echo "No commits ahead of ${base_ref}."
  fi
  echo ""

  # ── Changed Files ─────────────────────────────────────────────────────
  echo "## Changed Files"
  echo ""
  local stat_output
  stat_output="$(git diff --stat "${base_ref}...HEAD" 2>/dev/null || true)"
  if [[ -n "${stat_output}" ]]; then
    echo "${stat_output}"
  else
    echo "No changes between ${base_ref} and HEAD."
  fi

  # ── Diff (optional) ───────────────────────────────────────────────────
  if [[ "${show_diff}" == "yes" ]]; then
    echo ""
    echo "## Diff"
    echo ""
    if [[ -f "${diff_triage_script}" ]]; then
      python3 "${diff_triage_script}" -- "${base_ref}...HEAD"
    else
      git diff "${base_ref}...HEAD"
    fi
  fi
}

main "$@"
