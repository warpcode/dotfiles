# Script Patterns

Templates and conventions for wrapper scripts written during Phase 4.

---

## Standard Script Header

Every wrapper script MUST include this header block. It is the primary documentation for the LLM reading the skill.

```bash
#!/usr/bin/env bash
# =============================================================================
# SCRIPT:  <script-name>.sh
# PURPOSE: <one-line description of what this script does>
# USAGE:   ./<script-name>.sh [OPTIONS]
#
# OPTIONS:
#   -r, --repo <owner/repo>   Target repository (default: current repo)
#   -s, --state <state>       Filter by state: open|closed|all (default: open)
#   -l, --label <label>       Filter by label (repeatable)
#
# OUTPUT:
#   JSON array to stdout. Each element: { "number": int, "title": str, "state": str }
#   Exit 0 on success, non-zero on error (stderr contains reason).
#
# DEPENDENCIES: gh, jq
# =============================================================================
set -euo pipefail
```

The **OUTPUT** section is the most important part for LLM skill documentation — it tells the skill what shape of data to expect so the LLM can parse it reliably.

---

## Pattern 1: List + Filter

Use when the CLI has a list command with `--json` and you want to pre-filter before handing results to the LLM. Reduces tokens spent on irrelevant items.

```bash
#!/usr/bin/env bash
# =============================================================================
# SCRIPT:  list-my-prs.sh
# PURPOSE: List open PRs assigned to the current user, JSON output
# USAGE:   ./list-my-prs.sh [--repo <owner/repo>] [--state <state>]
#
# OUTPUT:
#   JSON array: [{ "number": int, "title": str, "state": str,
#                  "reviewDecision": str, "isDraft": bool }]
# DEPENDENCIES: gh, jq
# =============================================================================
set -euo pipefail

REPO=""
STATE="open"

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--repo)  REPO="$2"; shift 2 ;;
    -s|--state) STATE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

REPO_FLAG=""
[[ -n "$REPO" ]] && REPO_FLAG="--repo $REPO"

gh pr list \
  $REPO_FLAG \
  --author "@me" \
  --state "$STATE" \
  --json number,title,state,reviewDecision,isDraft
```

**Why this saves tokens:** `gh pr list` without `--json` produces a formatted table with colour codes. With `--json` and explicit field selection, the LLM receives only the data it needs — no decorative output, no parsing required.

---

## Pattern 2: Bulk Operation

Use when the agent needs to apply the same operation to N items. Collapses N tool calls into 1 script invocation.

```bash
#!/usr/bin/env bash
# =============================================================================
# SCRIPT:  bulk-label-issues.sh
# PURPOSE: Apply a label to a list of issue numbers
# USAGE:   ./bulk-label-issues.sh --label <label> < issue-numbers.txt
#          echo -e "42\n43\n44" | ./bulk-label-issues.sh --label "triaged"
#
# INPUT:   Newline-separated issue numbers on stdin
# OUTPUT:  Progress to stderr; JSON summary to stdout on completion:
#          { "labelled": [int], "failed": [int] }
# DEPENDENCIES: gh, jq
# =============================================================================
set -euo pipefail

LABEL=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--label) LABEL="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LABEL" ]] && { echo "Error: --label required" >&2; exit 1; }

LABELLED=()
FAILED=()

while IFS= read -r number; do
  [[ -z "$number" ]] && continue
  if gh issue edit "$number" --add-label "$LABEL" >/dev/null 2>&1; then
    echo "✓ #$number" >&2
    LABELLED+=("$number")
  else
    echo "✗ #$number" >&2
    FAILED+=("$number")
  fi
done

# Output JSON summary
jq -n \
  --argjson labelled "$(printf '%s\n' "${LABELLED[@]:-}" | jq -R . | jq -s .)" \
  --argjson failed "$(printf '%s\n' "${FAILED[@]:-}" | jq -R . | jq -s .)" \
  '{ labelled: ($labelled | map(tonumber)), failed: ($failed | map(tonumber)) }'
```

**Key conventions for bulk scripts:**
- Accept input on stdin (newline-separated IDs) so the LLM can pipe the output of a list operation directly
- Emit progress to stderr (LLM ignores it; humans see it during testing)
- Emit a structured JSON summary to stdout (LLM parses the outcome)
- Never stop on first failure — collect errors and report all at end

---

## Pattern 3: Pagination Handler

Use when the CLI's `--limit` caps results and the agent needs the full set.

```bash
#!/usr/bin/env bash
# =============================================================================
# SCRIPT:  list-all-issues.sh
# PURPOSE: Fetch ALL open issues regardless of API pagination limits
# USAGE:   ./list-all-issues.sh [--repo <owner/repo>] [--label <label>]
#
# OUTPUT:
#   JSON array of all matching issues (no truncation):
#   [{ "number": int, "title": str, "labels": [str], "createdAt": str }]
# DEPENDENCIES: gh, jq
# NOTE: May be slow for repos with thousands of issues. Uses --limit 1000
#       per page; gh handles cursor pagination internally at this limit.
# =============================================================================
set -euo pipefail

REPO_FLAG=""
LABEL_FLAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--repo)  REPO_FLAG="--repo $2"; shift 2 ;;
    -l|--label) LABEL_FLAG="--label $2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# gh issue list handles pagination internally when --limit is large
gh issue list \
  $REPO_FLAG \
  $LABEL_FLAG \
  --state open \
  --limit 1000 \
  --json number,title,labels,createdAt \
| jq '[.[] | .labels = [.labels[].name]]'
```

**Note on pagination:** Some CLIs (like `gh`) handle cursor pagination internally when you set a high `--limit`. Others require explicit cursor passing. Check the docs. If explicit cursors are needed, the script becomes a loop; document the loop exit condition clearly.

---

## Pattern 4: Composite Workflow

Use when the agent task requires multiple CLI operations that form a logical unit. The script becomes the unit of work rather than each individual command.

```bash
#!/usr/bin/env bash
# =============================================================================
# SCRIPT:  pr-ready-to-merge.sh
# PURPOSE: Check if a PR is approved, CI-passing, and not a draft
# USAGE:   ./pr-ready-to-merge.sh --pr <number> [--repo <owner/repo>]
#
# OUTPUT:
#   JSON object:
#   { "ready": bool, "reasons": [str], "pr": { "number": int, "title": str } }
#   ready=true means it is safe to merge; reasons lists any blockers.
# DEPENDENCIES: gh, jq
# =============================================================================
set -euo pipefail

PR=""
REPO_FLAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--pr)   PR="$2"; shift 2 ;;
    -r|--repo) REPO_FLAG="--repo $2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$PR" ]] && { echo "Error: --pr required" >&2; exit 1; }

DATA=$(gh pr view "$PR" $REPO_FLAG \
  --json number,title,isDraft,reviewDecision,statusCheckRollup)

IS_DRAFT=$(echo "$DATA" | jq -r '.isDraft')
REVIEW=$(echo "$DATA" | jq -r '.reviewDecision')
CI=$(echo "$DATA" | jq -r '[.statusCheckRollup[]?.conclusion] | 
     if length == 0 then "UNKNOWN"
     elif all(. == "SUCCESS") then "PASS"
     else "FAIL" end')

REASONS=()
[[ "$IS_DRAFT" == "true" ]]      && REASONS+=("PR is a draft")
[[ "$REVIEW" != "APPROVED" ]]    && REASONS+=("Review decision: $REVIEW")
[[ "$CI" != "PASS" ]]            && REASONS+=("CI status: $CI")

READY="false"
[[ ${#REASONS[@]} -eq 0 ]] && READY="true"

echo "$DATA" | jq \
  --argjson ready "$READY" \
  --argjson reasons "$(printf '%s\n' "${REASONS[@]:-}" | jq -R . | jq -s .)" \
  '{ ready: $ready, reasons: $reasons, pr: { number: .number, title: .title } }'
```

**Why this saves tool calls:** Without this script, the agent would need to: (1) call `gh pr view`, (2) call `gh pr checks`, (3) reason about the combined result across two tool calls. The script folds it into one.

---

## Token Efficiency Reference

Across all scripts, apply these practices to minimise token usage:

| Practice | Saves tokens | Example |
|---|---|---|
| Use `--json` with explicit fields | Eliminates decorative output | `--json number,title,state` |
| Pipe through `jq` to filter | Removes unwanted fields | `jq '{number, title}'` |
| Pre-filter in the script | LLM sees only relevant items | `--state open --author @me` |
| Emit structured summaries not logs | LLM parses JSON not prose | `{ "merged": [1,2], "failed": [3] }` |
| Use `--quiet` or `--no-color` | Eliminates ANSI codes | `--no-color` |
| One composite script over many calls | Fewer round-trips | Pattern 4 above |

---

## Referencing Scripts in SKILL.md

In the skill's SKILL.md, reference each script like this:

```markdown
## Wrapper Scripts

### `scripts/list-my-prs.sh`
Lists open PRs authored by the current user.

**Input:** Optional `--repo <owner/repo>`, `--state <open|closed|all>`  
**Output:** JSON array — `[{ "number": int, "title": str, "state": str, "reviewDecision": str, "isDraft": bool }]`  
**Use when:** You need a filtered, machine-readable list of the user's own PRs.

Invoke with:
```bash
bash scripts/list-my-prs.sh --state open
```
```

Always include: path, purpose, input flags, output schema, and the conditions under which the LLM should prefer this script over a direct `gh` invocation.
