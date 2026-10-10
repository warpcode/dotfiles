# Pull Request Templates

Fallback when repo has no `.github/PULL_REQUEST_TEMPLATE.md`. Adapt to fit — drop empty sections.

---

## Standard

```markdown
## Summary
{what this PR does and why — 1-3 sentences}

## Changes
- {change 1}
- {change 2}
- {change 3}

## Related Issues
{Closes #X, Fixes #Y, or "None"}

## Testing
{how the changes were tested — manual steps, test commands, or "N/A" for docs-only}

## Screenshots
{before/after if UI changed — omit if not applicable}

## Notes for Reviewers
{anything reviewers should pay special attention to — omit if nothing unusual}
```

---

## Hotfix

```markdown
## Summary
{what broke and what this fixes}

## Root Cause
{why the issue occurred}

## Fix
- {change 1}
- {change 2}

## Testing
{how the fix was verified}

## Risk Assessment
{impact of this change, rollback plan if applicable}
```

---

## Refactor

```markdown
## Summary
{what was restructured and why}

## Motivation
{why the refactor is needed now}

## Changes
- {structural change 1}
- {structural change 2}

## Behavioral Impact
{confirm no behavior change, or describe any intentional behavior changes}

## Testing
{how correctness was verified after refactoring}
```

---

## Documentation

```markdown
## Summary
{what documentation was added or updated}

## Changes
- {doc change 1}
- {doc change 2}

## Related Issues
{Closes #X or "None"}
```

---

## Template Selection

| Signal | Template |
|--------|----------|
| New feature, enhancement, general work | Standard |
| Emergency fix, production bug, urgent | Hotfix |
| Restructure, cleanup, no behavior change | Refactor |
| Docs only, README, guides | Documentation |

Default: Standard.
