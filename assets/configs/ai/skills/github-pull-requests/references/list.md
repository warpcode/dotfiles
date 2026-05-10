# Listing PRs

When the user wants to search, filter, or browse pull requests.

## Basic listing

```bash
# Open PRs (default)
gh pr list --state open --limit 30

# All states
gh pr list --state all --limit 30

# Closed / merged
gh pr list --state closed --limit 30
gh pr list --state merged --limit 30
```

## Filtered queries

| Filter | Command |
|--------|---------|
| By label | `gh pr list --label "bug" --limit 30` |
| By author | `gh pr list --author "alice" --limit 30` |
| By assignee | `gh pr list --assignee "@me" --limit 30` |
| By base branch | `gh pr list --base "develop" --limit 30` |
| By head branch | `gh pr list --head "feat/dark-mode"` |
| Drafts only | `gh pr list --draft --limit 30` |
| Needing my review | `gh pr list --search "review-requested:@me" --limit 30` |
| Full text search | `gh pr list --search "dark mode sort:updated-desc" --limit 20` |

## JSON output for processing

When you need structured data:

```bash
gh pr list --state open --limit 30 --json \
  number,title,state,isDraft,author,labels,\
  assignees,reviewRequests,url,createdAt,updatedAt
```

## Present results

Format results in a scannable table:

```
#47  [enhancement]  feat(ui): Add dark mode toggle    draft   @alice  2d ago
#45  [bug]          fix(api): Handle null responses    open    @bob    3d ago
#42  [docs]         docs: Update API reference         open    @charlie 1w ago
```

Include the draft/open state so the user can tell at a glance which PRs are ready for review.

## Cross-repo queries

For operations on a different repo, pass `-R owner/repo`:

```bash
gh pr list -R owner/other-repo --state open --limit 20
gh pr view 42 -R owner/other-repo
```
