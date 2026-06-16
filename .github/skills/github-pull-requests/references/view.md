# Viewing a PR

When the user wants to inspect a specific PR — its description, comments, review status, CI checks, or merge readiness.

## Identify the PR

Resolve which PR to view:

1. **Explicit** — User gives a PR number (`#47`) or URL
2. **Current branch** — Script auto-detects if no number is provided
3. **Ask** — If neither works, ask

## Fetch PR details

Run the view script from this skill's `scripts/` directory:

```bash
# With explicit PR number
bash /path/to/this/skill/scripts/view.sh 47

# Auto-detect from current branch
bash /path/to/this/skill/scripts/view.sh
```

The script fetches all metadata, comments, and diff in one shot and outputs a formatted summary:

```markdown
# PR #47: feat(ui): Add dark mode toggle

| Detail | Value |
|--------|-------|
| State | Draft |
| Branch | feat/dark-mode → main |
| Author | @alice |
| Assignees | @alice, @bob |
| Labels | enhancement, ui |
| Changes | +142 -38 across 7 files |
| Mergeable | MERGEABLE |
| Merge state | BLOCKED |
| URL | https://github.com/owner/repo/pull/47 |
| Created | 2 days ago |
| Updated | 3 hours ago |

## Reviews

✅ @bob — APPROVED
🔄 @charlie — CHANGES_REQUESTED

## Pending Review Requests

⏳ @dave

## CI Status

✅ build — SUCCESS
✅ lint — SUCCESS
❌ test-e2e — FAILURE
⏳ deploy-preview — IN_PROGRESS

## Output Files

| File | Path | Lines | Size |
|------|------|------:|------|
| Full JSON | /tmp/pr-view.XXXXXX/pr.json | — | 12 KB |
| Comments | /tmp/pr-view.XXXXXX/comments.txt | 45 | 3 KB |
| Diff | /tmp/pr-view.XXXXXX/changes.diff | 340 | 15 KB |
```

## How to handle the output

The formatted summary covers most user queries directly. For deeper dives:

| User asks about | Action |
|-----------------|--------|
| General status | The summary output has everything — just present it |
| Comments / discussion | Read the comments file |
| Specific review feedback | Read the JSON file, filter `reviews` for `CHANGES_REQUESTED` state |
| Full diff | Read the diff file (use line count/size to decide: read directly or spawn subagent) |
| Merge readiness | Check the summary: all reviews approved? CI passing? Mergeable not `CONFLICTING`? Not draft? |

Clean up the temp directory when you're done.
