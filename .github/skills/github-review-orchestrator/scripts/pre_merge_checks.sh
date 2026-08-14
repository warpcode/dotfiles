#!/usr/bin/env zsh
# General pre-merge and pre-approval validation checks for PR branches.
# Usage: ./scripts/pre_merge_checks.sh <pr_number>

PR_NUMBER="${1:-}"
if [[ -z "$PR_NUMBER" ]]; then
  echo "Usage: $0 <pr_number>" >&2
  exit 1
fi

echo "=== Running PR Pre-Merge Checks ==="

OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')

# 1. Fetch PR details in a single invocation
PR_INFO=$(gh pr view "$PR_NUMBER" --json headRefName,reviewDecision,mergeable,statusCheckRollup 2>/dev/null)
if [[ -z "$PR_INFO" ]]; then
  echo "Error: Could not retrieve info for PR #$PR_NUMBER" >&2
  exit 1
fi

BRANCH_NAME=$(jq -r '.headRefName // empty' <<< "$PR_INFO")
DECISION=$(jq -r '.reviewDecision // empty' <<< "$PR_INFO")
MERGEABLE=$(jq -r '.mergeable // empty' <<< "$PR_INFO")

echo "PR Branch: $BRANCH_NAME"

FAILED=0
WARNINGS=0

# 2. Check: Has all the requested changes been resolved?
echo "Checking unresolved review threads..."
UNRESOLVED_THREADS=$(gh api graphql -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER" -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(last: 50) {
          nodes {
            isResolved
            comments(first: 1) {
              nodes {
                body
              }
            }
          }
        }
      }
    }
  }
' 2>/dev/null)

if [[ -n "$UNRESOLVED_THREADS" ]]; then
  UNRESOLVED_COUNT=$(jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length' <<< "$UNRESOLVED_THREADS")
  if (( UNRESOLVED_COUNT > 0 )); then
    echo "❌ Unresolved changes: There are $UNRESOLVED_COUNT unresolved review threads." >&2
    FAILED=1
  else
    echo "✓ All requested changes / review threads are resolved."
  fi
else
  echo "✓ No review threads found."
fi

# 3. Check: Has the pull request been approved?
echo "Checking review approval status..."
if [[ "$DECISION" == "APPROVED" ]]; then
  echo "✓ Pull request is APPROVED."
else
  echo "❌ Review Decision: $DECISION (Not Approved)." >&2
  FAILED=1
fi

# 4. Check: Are there any merge conflicts listed?
echo "Checking merge conflicts..."
if [[ "$MERGEABLE" == "MERGEABLE" ]]; then
  echo "✓ No merge conflicts listed. Merge state is clean."
elif [[ "$MERGEABLE" == "CONFLICTING" ]]; then
  echo "❌ Merge Conflicts: Branch has conflicts that must be resolved." >&2
  FAILED=1
else
  echo "⚠ Mergeability status is unknown or pending: $MERGEABLE"
  WARNINGS=1
fi

# 5. Check: Have all the github actions finished running? Are they successful?
echo "Checking GitHub Actions / status checks..."
CHECK_COUNT=$(jq '.statusCheckRollup | length' <<< "$PR_INFO")
if (( CHECK_COUNT > 0 )); then
  # Group statuses using jq
  PENDING_CHECKS=$(jq '[.statusCheckRollup[] | select(.state == "PENDING")] | length' <<< "$PR_INFO")
  FAILING_CHECKS=$(jq '[.statusCheckRollup[] | select(.state == "FAILURE" or .state == "ERROR")] | length' <<< "$PR_INFO")
  
  if (( FAILING_CHECKS > 0 )); then
    echo "⚠ Warning: $FAILING_CHECKS checks failed."
    WARNINGS=1
  fi
  
  if (( PENDING_CHECKS > 0 )); then
    echo "⚠ Warning: $PENDING_CHECKS checks are still pending."
    WARNINGS=1
  fi
  
  if (( FAILING_CHECKS == 0 && PENDING_CHECKS == 0 )); then
    echo "✓ All status checks completed successfully."
  fi
else
  echo "✓ No status checks reported on this branch."
fi

# 6. Check: General code cleanliness (Syntax / Interactive Safety)
echo "Checking general code cleanliness of modified files..."
# Ensure local branches are up-to-date before running local checks
git fetch origin "$BRANCH_NAME" >/dev/null 2>&1 || true

MODIFIED_FILES=(${(f)"$(git diff --name-only origin/master...origin/$BRANCH_NAME 2>/dev/null)"})

for file in "${MODIFIED_FILES[@]}"; do
  if [[ "$file" == *.zsh || "$file" == bin/df.* || "$file" == *.sh ]]; then
    TEMP_FILE=$(mktemp)
    git show "origin/$BRANCH_NAME:$file" > "$TEMP_FILE" 2>/dev/null
    
    # Syntax check
    if [[ "$file" == *.sh ]]; then
      bash -n "$TEMP_FILE" 2>/dev/null
    else
      zsh -n "$TEMP_FILE" 2>/dev/null
    fi
    
    if [[ $? -ne 0 ]]; then
      echo "❌ Syntax error in modified file: $file" >&2
      FAILED=1
    fi
    
    # Interactive safety: Zsh functions must use return, not exit
    if [[ "$file" == *.zsh || "$file" == bin/df.* ]]; then
      if grep -E '^\s*exit\s+' "$TEMP_FILE" >/dev/null; then
        echo "❌ Interactive safety violation: $file contains 'exit' statement instead of 'return'" >&2
        FAILED=1
      fi
    fi
    
    rm -f "$TEMP_FILE"
  fi
done

# 7. Scope Hygiene / File Purge checks
OBSOLETE_DIRS=("coding/tmp" "legacy" "tmp")
for dir in "${OBSOLETE_DIRS[@]}"; do
  for file in "${MODIFIED_FILES[@]}"; do
    if [[ "$file" == "$dir/"* ]]; then
      echo "❌ Scope Hygiene violation: modified/added file in obsolete directory '$dir': $file" >&2
      FAILED=1
    fi
  done
done

echo "====================================="
if [[ $FAILED -eq 1 ]]; then
  echo "Status: FAILED"
  exit 1
elif [[ $WARNINGS -eq 1 ]]; then
  echo "Status: PASSED WITH WARNINGS"
  exit 0
else
  echo "Status: PASSED"
  exit 0
fi
