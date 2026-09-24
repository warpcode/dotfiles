#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
pull_number=""
admin=""
requested_method=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./merge_pull_request.sh [OPTIONS]"
      echo ""
      echo "Merge an open pull request into its target base branch."
      echo ""
      echo "Options:"
      echo "  --owner <value>                   (Required)"
      echo "  --repo <value>                    (Required)"
      echo "  --pull-number <value>             (Required)"
      echo "  --merge-method, --type <squash|merge|rebase>"
      echo "                                    Merge strategy (defaults to auto-detected allowed method, preferring squash)"
      echo "  --admin                           Use administrator privileges to immediately merge"
      echo "  -h, --help                        Show this help message"
      exit 0
      ;;
    --owner)
      owner="$2"
      shift 2
      ;;
    --repo)
      repo="$2"
      shift 2
      ;;
    --pull-number)
      pull_number="$2"
      shift 2
      ;;
    --merge-method|--type)
      requested_method="$2"
      shift 2
      ;;
    --admin)
      admin="--admin"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$owner" ]]; then
  echo "Error: --owner is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$repo" ]]; then
  echo "Error: --repo is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$pull_number" ]]; then
  echo "Error: --pull-number is required. Use --help for usage." >&2
  exit 1
fi

base_branch_json="$(gh pr view "$pull_number" --repo "$owner"/"$repo" --json baseRefName 2>/dev/null || echo '')"
base_branch="$(echo "$base_branch_json" | jq -r '.baseRefName // empty' 2>/dev/null || echo '')"
if [[ -z "$base_branch" ]]; then
  echo "Error: Could not determine base branch for PR #$pull_number in $owner/$repo." >&2
  exit 1
fi

# Detect allowed merge methods
allowed_methods=()

# 1. Try branch ruleset evaluation
rules_json="$(gh api "repos/${owner}/${repo}/rules/branches/${base_branch}" 2>/dev/null || echo '')"
if [[ -n "$rules_json" ]]; then
  mapfile -t rule_methods < <(echo "$rules_json" | jq -r '.[]? | select(.type=="pull_request") | .parameters.allowed_merge_methods[]? // empty' 2>/dev/null || true)
  if [[ ${#rule_methods[@]} -gt 0 ]]; then
    for m in "${rule_methods[@]}"; do
      m_lower="$(echo "$m" | tr '[:upper:]' '[:lower:]')"
      if [[ "$m_lower" == "squash" || "$m_lower" == "merge" || "$m_lower" == "rebase" ]]; then
        allowed_methods+=("$m_lower")
      fi
    done
  fi
fi

# 2. Fallback to repository settings if no branch ruleset specified merge methods
if [[ ${#allowed_methods[@]} -eq 0 ]]; then
  repo_json="$(gh api "repos/${owner}/${repo}" 2>/dev/null || echo '')"
  if [[ -n "$repo_json" ]]; then
    if [[ "$(echo "$repo_json" | jq -r '.allow_squash_merge // false')" == "true" ]]; then
      allowed_methods+=("squash")
    fi
    if [[ "$(echo "$repo_json" | jq -r '.allow_merge_commit // false')" == "true" ]]; then
      allowed_methods+=("merge")
    fi
    if [[ "$(echo "$repo_json" | jq -r '.allow_rebase_merge // false')" == "true" ]]; then
      allowed_methods+=("rebase")
    fi
  fi
fi

# If auto-detection yielded no methods, default to squash as fallback
if [[ ${#allowed_methods[@]} -eq 0 ]]; then
  allowed_methods=("squash")
fi

# Build allowed list display string (e.g. "squash, merge, rebase")
allowed_list="$(printf "%s, " "${allowed_methods[@]}")"
allowed_list="${allowed_list%, }"

selected_method=""
if [[ -n "$requested_method" ]]; then
  req_lower="$(echo "$requested_method" | tr '[:upper:]' '[:lower:]')"
  is_allowed=0
  for m in "${allowed_methods[@]}"; do
    if [[ "$m" == "$req_lower" ]]; then
      is_allowed=1
      break
    fi
  done

  if [[ $is_allowed -eq 0 ]]; then
    echo "Error: Merge method '$requested_method' is not allowed for branch '$base_branch'. Allowed methods: $allowed_list" >&2
    exit 1
  fi
  selected_method="$req_lower"
else
  # Default Method Selection: prefer squash if allowed, else first allowed method
  is_squash_allowed=0
  for m in "${allowed_methods[@]}"; do
    if [[ "$m" == "squash" ]]; then
      is_squash_allowed=1
      break
    fi
  done

  if [[ $is_squash_allowed -eq 1 ]]; then
    selected_method="squash"
  else
    selected_method="${allowed_methods[0]}"
  fi
fi

gh pr merge "$pull_number" --repo "$owner"/"$repo" "--$selected_method" --delete-branch ${admin:+"$admin"}
