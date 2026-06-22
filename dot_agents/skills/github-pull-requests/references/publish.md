# Publishing a PR

When the user wants to mark a draft PR as ready for review.

## Pre-checks

Run both scripts to gather the full picture:

1. **View script** — fetch the PR details and confirm it's currently a draft:

```bash
bash /path/to/this/skill/scripts/view.sh <number>
```

Check the `State` field in the summary. If it's not `Draft`, tell the user — no action needed.

2. **Pre-flight script** — check for unpushed commits or uncommitted changes:

```bash
bash /path/to/this/skill/scripts/preflight.sh
```

If there are unpushed commits or uncommitted changes, warn the user — the published PR won't reflect their latest local state. Ask if they want to push/commit first.

## Review before publishing

Present the key details from the view script output:

```
🚀 Ready to publish PR #47:

  Title:     feat(ui): Add dark mode toggle
  Labels:    enhancement
  Reviewers: alice, bob
  URL:       https://github.com/owner/repo/pull/47

This will mark the PR as ready for review and notify reviewers.
Proceed?
```

## Execute

```bash
gh pr ready <number>
```

## Confirm

```
✅ PR #47 is now ready for review: https://github.com/owner/repo/pull/47
```
