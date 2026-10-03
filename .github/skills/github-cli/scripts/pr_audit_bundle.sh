#!/bin/bash
# pr_audit_bundle.sh - Collect everything needed for a non-invasive PR audit in one call.
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

usage() {
  cat <<'EOF'
Usage: pr_audit_bundle.sh --repo <owner/repo> --pr <number> [--out <dir>]

Non-invasive PR audit bundle (no checkout, no workspace tests). Writes into <out>
(default: ./scratch/pr<number>):
  meta.json          PR metadata (title, body, files, commits, reviews, checks)
  pr<number>.diff    Full unified diff (read it with view_file ranges, NOT stdout)
  head/<path>        Raw head-branch copy of every added/modified file
  issues/<n>.json    Source issues (Fixes/Closes/Resolves + closingIssuesReferences)
Then prints a concise Markdown summary: files, CI rollup, source issues with their
acceptance-criteria checkboxes, and 'depends on #N' issues with shipped status
(merged PR found, not merely CLOSED).

Options:
  --repo <owner/repo>  Required. Never guessed from the local directory.
  --pr <number>        Required.
  --out <dir>          Output directory.
  -h, --help           Show this help.
EOF
}

repo=""
pr=""
out=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) usage; exit 0 ;;
    --repo) repo="$2"; shift 2 ;;
    --pr) pr="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$repo" || -z "$pr" ]]; then
  echo "Error: --repo and --pr are required. Use --help for usage." >&2
  exit 1
fi
[[ -z "$out" ]] && out="scratch/pr${pr}"
mkdir -p "$out/head" "$out/issues"

gh pr view "$pr" --repo "$repo" \
  --json number,title,body,author,headRefName,baseRefName,state,files,commits,reviews,comments,statusCheckRollup,closingIssuesReferences \
  > "$out/meta.json"
gh api "repos/${repo}/pulls/${pr}" -H "Accept: application/vnd.github.v3.diff" > "$out/pr${pr}.diff"

head_ref="$(jq -r '.headRefName' "$out/meta.json")"

# Head copies of non-deleted files.
jq -r '.files[] | select(.changeType != "DELETED") | .path' "$out/meta.json" | while IFS= read -r path; do
  mkdir -p "$out/head/$(dirname "$path")"
  gh api "repos/${repo}/contents/${path}?ref=${head_ref}" -H "Accept: application/vnd.github.raw" \
    > "$out/head/$path" 2>/dev/null || echo "warn: could not fetch $path" >&2
done

# Source issues: closing references + Fixes/Closes/Resolves #N in body.
{
  jq -r '.closingIssuesReferences[]?.number' "$out/meta.json"
  jq -r '.body // ""' "$out/meta.json" | grep -oiE '(fix(es|ed)?|close[sd]?|resolve[sd]?) +#[0-9]+' | grep -oE '[0-9]+' || true
} | sort -un > "$out/issues/_list.txt"

while IFS= read -r n; do
  [[ -z "$n" ]] && continue
  gh issue view "$n" --repo "$repo" --json number,title,body,state,comments > "$out/issues/${n}.json"
done < "$out/issues/_list.txt"

echo "# PR #${pr} audit bundle ($repo)"
jq -r '"**\(.title)** by \(.author.login) | \(.headRefName) -> \(.baseRefName) | \(.state) | \(.commits|length) commit(s)"' "$out/meta.json"
echo
echo "## Files"
jq -r '.files[] | "- \(.changeType) \(.path) (+\(.additions)/-\(.deletions))"' "$out/meta.json"
echo
echo "## CI"
jq -r '[.statusCheckRollup[]? | "\(.name // .context): \(.conclusion // .state // .status)"] | unique | .[] | "- " + .' "$out/meta.json"
echo
echo "## Source issues"
while IFS= read -r n; do
  [[ -z "$n" ]] && continue
  echo "### #${n}: $(jq -r '.title' "$out/issues/${n}.json")"
  jq -r '.body // ""' "$out/issues/${n}.json" | grep -E '^\s*- \[[ xX]\]' || echo "(no checkbox acceptance criteria found; read issues/${n}.json)"
  # Dependencies: "depends on #M" in the issue body.
  jq -r '.body // ""' "$out/issues/${n}.json" | grep -oiE 'depend[a-z]* +on +(issue +)?#[0-9]+' | grep -oE '[0-9]+' | sort -un | while IFS= read -r m; do
    state="$(gh issue view "$m" --repo "$repo" --json state -q .state)"
    merged="$(gh pr list --repo "$repo" --state merged --search "#${m}" --json number --limit 5 -q 'map("#"+(.number|tostring))|join(",")')"
    echo "- depends on #${m}: ${state}; merged PRs mentioning it: ${merged:-NONE (CLOSED != shipped)}"
  done
done < "$out/issues/_list.txt"
echo
echo "Bundle written to: $out"
