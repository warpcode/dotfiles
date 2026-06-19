# Decomposition Heuristics

Detailed guidance and worked examples for Phase 3 decomposition decisions.

---

## When Domain Splitting Is Worth It

Split into multiple skills when the answer to **most** of these is "yes":

| Question | Signals split |
|---|---|
| Do the domains address completely different nouns? (PRs vs Issues vs Repos) | Yes |
| Would activating a single combined skill load > 40% irrelevant content per typical task? | Yes |
| Does each domain have > ~80 lines of useful documentation? | Yes |
| Are the domains used by different agent types? (read agent vs write agent) | Yes |
| Do the domains have non-overlapping flags and output schemas? | Yes |

Keep combined when:
- The total content for all domains is < 200 lines
- Domain operations share significant flag overlap
- Tasks naturally cross domain boundaries (e.g. creating a PR always touches a branch, which is another domain — but that's fine, activate both skills)

---

## GitHub CLI — Worked Example

**Discovery output:** `gh` has ~15 top-level subcommands spanning auth, repo management, PRs, issues, releases, Actions, and secrets.

**Analysis:** The subcommands cluster into 5 distinct domains:

| Domain | Subcommands | Type |
|---|---|---|
| Pull Requests | `pr` | read + write |
| Issues | `issue` | read + write |
| Repository | `repo` | read + write |
| Actions | `run`, `workflow` | read + write |
| Admin | `secret`, `auth`, `config` | read + write |

**Decision:** Five separate skills. Rationale:
- A PR-review agent needs `gh-pr`; it never needs `gh-secret`
- An incident responder needs `gh-issue`; it never needs `gh-workflow`
- Each domain has 80–150 lines of meaningful documentation
- Skills can co-activate — a release workflow agent can load `gh-pr` + `gh-repo` + `gh-workflow` simultaneously with no conflict

**Result:**
```
gh-pr         → pull request lifecycle
gh-issue      → issue management and search  
gh-repo       → repository operations
gh-actions    → workflow runs and triggers
gh-admin      → auth, config, secrets (likely read-only for most agents)
```

---

## Simple CLI — Worked Example

**CLI:** `jq` (JSON processor, no subcommands)

**Discovery:** `jq --help`, man page, `jq` manual online.

**Analysis:** Single operational mode. No subcommands. Rich filter language.

**Decision:** One skill. However, the filter language is complex enough to warrant a `references/filters.md` with common filter patterns, rather than embedding them all in SKILL.md.

**Result:**
```
jq/
├── SKILL.md           → invocation, common patterns, constraints
└── references/
    └── filters.md     → filter syntax reference: select, map, reduce, paths
```

---

## Moderately Complex CLI — Worked Example

**CLI:** `ffmpeg` (audio/video processing)

**Discovery:** `ffmpeg --help full` (very long), `ffmpeg -formats`, `ffmpeg -codecs`, man page, official docs.

**Analysis:** No traditional subcommands, but distinct use modes:

| Mode | Description | Operation |
|---|---|---|
| Transcode | Convert container/codec | write (destructive to files) |
| Stream | Network streaming | write |
| Probe | Inspect media metadata | read only |
| Filters | Apply filters/effects | write |

`ffprobe` is a separate binary (read-only inspection) — this is already a natural read/write split at the binary level.

**Decision:** Two skills:
- `ffprobe` — read-only media inspection
- `ffmpeg-transcode` — conversion patterns only (the most common agent use case)

Full `ffmpeg` functionality is too large for one skill. Scope to the most common agent task.

**Result:**
```
ffprobe/
├── SKILL.md           → inspect media files, extract metadata as JSON
ffmpeg-transcode/
├── SKILL.md           → format conversion, codec selection, output sizing
└── references/
    └── codecs.md      → common codec + container combinations
```

---

## Read/Write Split — When It Matters

### Scenario 1: Investigation agent (read-only)

An agent tasked with auditing open PRs, summarising issues, or reporting on repo status should **never** be able to merge, close, or create. Give it only the read skill:

```
gh-pr-read    → list, view, diff, review comments, check status
gh-issue-read → list, view, search, label list
```

The write counterparts (`gh-pr-write`, `gh-issue-write`) are not activated for this agent.

### Scenario 2: Triage agent (read + constrained write)

A triage agent might read issues and apply labels — but should not close or delete. Options:

1. Activate the combined skill and add a constraint: `MUST NOT run gh issue close or gh issue delete without explicit user confirmation`
2. Extract a `gh-issue-triage` skill that only documents the label/assign operations

Option 1 is simpler. Option 2 is safer for automated pipelines.

### Scenario 3: Full automation (read + write)

A release automation agent needs to list PRs, check CI status, merge, and create releases. Use the combined skills and document the write operations clearly.

---

## The Overlap Concern

> "Should we separate skills? But what if their uses overlap?"

This is not a problem. Two skills can document overlapping concepts without conflicting. Example:

- `gh-pr` documents that PRs are linked to issues via `Closes #N`
- `gh-issue` documents that issues can be closed by a merged PR

Both facts are true. Activating both skills doesn't cause contradiction — it gives the LLM richer context. The duplication cost is a few lines of text. The benefit is that each skill is self-contained when activated alone.

The only duplication to avoid: **identical command examples** that serve no additional purpose in both skills. Keep those in the most natural home and cross-reference.

---

## Scope Limiting

Not every CLI feature needs to be in a skill. Scope to what is realistic for an LLM agent to use:

| Realistic for LLM agents | Probably not |
|---|---|
| `gh pr list --json` | `gh codespace create` (interactive) |
| `gh issue create --body "$body"` | `gh browse` (opens browser) |
| `gh run list --workflow ci.yml` | `gh auth login` (OAuth flow) |
| `ffprobe -v quiet -print_format json` | `ffmpeg` live stream capture |

Exclude interactive, OAuth, and UI-dependent operations from skills. Note their exclusion and why.
