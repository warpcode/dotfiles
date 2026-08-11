# Issue Templates

Fallback when repo has no `.github/ISSUE_TEMPLATE/`. Adapt to fit — drop empty sections.

---

## Bug Report

```markdown
## Description
{broken behavior + user impact}

## Steps to Reproduce
1.
2.
3.

## Expected Behavior
{correct behavior}

## Actual Behavior
{observed behavior, errors, traces}

## Environment
- OS:
- Version/Commit:
- Runtime:

## Additional Context
{logs, related issues, workarounds — omit if empty}
```

---

## Feature Request

```markdown
## Summary
{what + why}

## Motivation
{problem solved or opportunity}

## Proposed Solution
{implementation approach}

## Acceptance Criteria
- [ ]
- [ ]
- [ ]

## Alternatives Considered
{other approaches + tradeoffs — omit if none}

## Additional Notes
{context, links, references — omit if empty}
```

---

## Task / Chore

```markdown
## Description
{what + why}

## Scope
{files, modules, areas affected}

## Acceptance Criteria
- [ ]
- [ ]
- [ ]

## Additional Notes
{context, links, references — omit if empty}
```

---

## Question / Discussion

```markdown
## Question
{specific question}

## Context
{goal, prior research, constraints}

## Options Considered
{candidate approaches with pros/cons}

## Additional Notes
{context, links, references — omit if empty}
```

---

## Security Vulnerability

Check `SECURITY.md` before filing publicly.

```markdown
## Summary
{vulnerability — no exploit code in public issues}

## Affected Versions
{versions or commits}

## Impact
{data exposure, privilege escalation, DoS, etc.}

## Suggested Fix
{proposed remediation — omit if unknown}

## Additional Notes
{context, links, references — omit if empty}
```

---

## Template Selection

| Signal | Template |
|--------|----------|
| crash, error, broken, regression, fails | Bug Report |
| add, support, feature, enhancement | Feature Request |
| refactor, deps, CI, docs, cleanup, chore | Task / Chore |
| RFC, thoughts on, discuss, how should we | Question / Discussion |
| vulnerability, CVE, security | Security Vulnerability |

Default: Bug Report (problems), Feature Request (ideas), Task/Chore (general).
