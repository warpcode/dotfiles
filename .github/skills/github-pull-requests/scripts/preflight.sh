#!/bin/bash
#
# Pre-flight checks for creating a GitHub pull request.
# Outputs a structured markdown report with all context needed
# to decide whether a PR can be created and what to ask the user.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

#######################################
# Verify gh CLI is installed and authenticated.
# Outputs:
#   "Yes" if ready, or a descriptive error string.
#######################################
check_gh_auth() {
  if ! command -v gh &>/dev/null; then
    echo "Not installed"
    return 0
  fi

  if ! gh auth status &>/dev/null; then
    echo "Not authenticated"
    return 0
  fi

  echo "Yes"
}

#######################################
# Get the current branch name.
# Outputs:
#   Branch name to stdout.
# Returns:
#   1 if not in a git repo or in detached HEAD.
#######################################
get_current_branch() {
  local branch
  branch="$(git branch --show-current 2>/dev/null)"
  if [[ -z "${branch}" ]]; then
    err "Not on a branch (detached HEAD or not a git repo)"
    return 1
  fi
  echo "${branch}"
}

#######################################
# Check if a branch is a mainline branch.
# Arguments:
#   $1 - Branch name.
# Returns:
#   0 if mainline, 1 otherwise.
#######################################
is_mainline_branch() {
  local branch="$1"
  [[ "${branch}" == "main" || "${branch}" == "master" ]]
}

#######################################
# Check if a branch exists on the remote.
# Arguments:
#   $1 - Branch name.
# Returns:
#   0 if exists on origin, 1 otherwise.
#######################################
branch_exists_on_remote() {
  local branch="$1"
  git ls-remote --heads origin "${branch}" 2>/dev/null | grep -q "${branch}"
}

#######################################
# Count commits on branch not yet pushed to origin.
# Arguments:
#   $1 - Branch name.
# Outputs:
#   Number of unpushed commits, or "N/A" if branch not on remote.
#######################################
get_unpushed_commits() {
  local branch="$1"
  local count
  count="$(git rev-list --count "origin/${branch}..HEAD" 2>/dev/null)" || true

  if [[ -z "${count}" ]]; then
    echo "N/A"
  else
    echo "${count}"
  fi
}

#######################################
# Get the repo's default branch name.
# Outputs:
#   Default branch name (e.g. "main"), or "Unknown".
#######################################
get_default_branch() {
  gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "Unknown"
}

#######################################
# Count total commits on this branch vs the default branch.
# Arguments:
#   $1 - Default branch name.
# Outputs:
#   Commit count, or "Unknown".
#######################################
get_commit_count() {
  local default_branch="$1"
  local count
  count="$(git rev-list --count "${default_branch}..HEAD" 2>/dev/null)" || true

  if [[ -z "${count}" ]]; then
    echo "Unknown"
  else
    echo "${count}"
  fi
}

#######################################
# Check for existing PRs on the current branch.
# Arguments:
#   $1 - Branch name.
# Outputs:
#   Markdown list of existing PRs, or "None" to stdout.
#######################################
get_existing_prs() {
  local branch="$1"
  local prs
  prs="$(gh pr list --head "${branch}" --json number,title,url 2>/dev/null)" || true

  if [[ -z "${prs}" || "${prs}" == "[]" ]]; then
    echo "None"
    return 0
  fi

  # Parse each PR into a markdown list item using gh's own formatting
  gh pr list --head "${branch}" \
    --json number,title,url \
    --template '{{range .}}- #{{.number}} {{.title}} — {{.url}}{{"\n"}}{{end}}' 2>/dev/null
}

#######################################
# Detect the repo's owner/name.
# Outputs:
#   "owner/repo" string to stdout, or "Unknown".
#######################################
get_repo_name() {
  gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Unknown"
}

#######################################
# Check for uncommitted changes.
# Outputs:
#   "Yes" or "No" to stdout.
#######################################
has_uncommitted_changes() {
  local status
  status="$(git status --porcelain 2>/dev/null)"
  if [[ -n "${status}" ]]; then
    echo "Yes"
  else
    echo "No"
  fi
}

#######################################
# Find a pull request template in the repo.
# Outputs:
#   Path to the template file, "Multiple: <dir>", or "None".
#######################################
find_pr_template() {
  local -a candidates=(
    ".github/PULL_REQUEST_TEMPLATE.md"
    ".github/pull_request_template.md"
    "docs/pull_request_template.md"
    "PULL_REQUEST_TEMPLATE.md"
  )

  for tmpl in "${candidates[@]}"; do
    if [[ -f "${tmpl}" ]]; then
      echo "${tmpl}"
      return 0
    fi
  done

  # Check for multiple-template directory
  if [[ -d ".github/PULL_REQUEST_TEMPLATE" ]]; then
    local -a templates
    templates=(.github/PULL_REQUEST_TEMPLATE/*.md)
    if [[ -e "${templates[0]}" ]]; then
      echo "Multiple: .github/PULL_REQUEST_TEMPLATE/"
      return 0
    fi
  fi

  echo "None"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Entry point. Runs all pre-flight checks and outputs markdown.
# Outputs:
#   Structured markdown report to stdout.
#######################################
main() {
  # Check gh CLI first — it's a hard prerequisite
  local gh_auth
  gh_auth="$(check_gh_auth)"

  local branch
  if ! branch="$(get_current_branch)"; then
    echo "# PR Pre-flight: FAILED"
    echo ""
    echo "**Error:** Not on a branch (detached HEAD or not a git repo)"
    return 0
  fi

  local is_mainline="No"
  if is_mainline_branch "${branch}"; then
    is_mainline="Yes"
  fi

  local on_remote="No"
  if branch_exists_on_remote "${branch}"; then
    on_remote="Yes"
  fi

  local unpushed="N/A"
  if [[ "${on_remote}" == "Yes" ]]; then
    unpushed="$(get_unpushed_commits "${branch}")"
  fi

  local existing_prs="None"
  local repo_name="Unknown"
  local default_branch="Unknown"

  # Only query gh API if authenticated
  if [[ "${gh_auth}" == "Yes" ]]; then
    existing_prs="$(get_existing_prs "${branch}")"
    repo_name="$(get_repo_name)"
    default_branch="$(get_default_branch)"
  fi

  local commit_count="Unknown"
  if [[ "${default_branch}" != "Unknown" ]]; then
    commit_count="$(get_commit_count "${default_branch}")"
  fi

  local uncommitted
  uncommitted="$(has_uncommitted_changes)"

  local pr_template
  pr_template="$(find_pr_template)"

  # Assemble the markdown report
  cat <<EOF
# PR Pre-flight

| Check               | Result |
|---------------------|--------|
| gh CLI              | ${gh_auth} |
| Branch              | ${branch} |
| Mainline branch     | ${is_mainline} |
| Pushed to origin    | ${on_remote} |
| Unpushed commits    | ${unpushed} |
| Uncommitted changes | ${uncommitted} |
| Repository          | ${repo_name} |
| Default branch      | ${default_branch} |
| Commit count        | ${commit_count} |
| PR template         | ${pr_template} |

## Existing PRs

${existing_prs}
EOF
}

main "$@"
