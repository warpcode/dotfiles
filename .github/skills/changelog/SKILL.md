---
name: changelog
description: >
  Create, update, format, audit, verify, and reconcile CHANGELOG.md files against
  git history and PR metadata with full provenance records. Use when scaffolding a
  changelog, generating release notes, extracting commit ranges and PR labels,
  recording changelog-provenance blocks, applying Keep a Changelog 1.1.0 and SemVer
  2.0.0 standards across libraries, CLIs, web apps, services, and monorepos, or
  detecting missing commits, range continuity gaps, and unrecorded labels.
---

# Changelog Knowledge Centre

Unified guide for authoring, updating, and auditing `CHANGELOG.md` files conforming to [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and [SemVer 2.0.0](https://semver.org/spec/v2.0.0.html), backed by machine-readable `changelog-provenance` YAML blocks.

## Core Domain Invariants

- **Keep a Changelog 1.1.0**: Human-readable release sections ordered chronologically with ISO 8601 dates (`YYYY-MM-DD`), an `[Unreleased]` top section, canonical headings (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, plus `Breaking Changes ⚠️` when applicable), and bottom compare links.
- **SemVer 2.0.0**: Breaking changes require a `MAJOR` bump, backward-compatible additions/deprecations require `MINOR`, and bug fixes/security patches require `PATCH`.
- **Provenance Tracking**: Every release section embeds a `<!-- changelog-provenance: ... -->` YAML comment recording `commit_range`, `base_commit`, `head_commit`, `compare_url`, `commit_count`, `prs_included`, `labels_recorded`, and an `omitted_or_internal` ledger so every commit in `<base>..<head>` is accounted for.

## When to Use

- Scaffolding a new `CHANGELOG.md` tailored to a library/SDK, CLI tool, web service, or monorepo.
- Extracting git commits and PR labels across `<base>..<head>` to draft `[Unreleased]` or tagged release entries.
- Embedding or validating `changelog-provenance` blocks and compare URLs.
- Auditing an existing `CHANGELOG.md` for missing commits/PRs, disjoint range continuity (`base_commit(N) != head_commit(N-1)`), misclassified labels, non-ISO dates, or SemVer drift.
- Running a strict pre-release CI gate or producing a formal Markdown changelog audit report.

## Domain References

| Reference | Read When |
|---|---|
| `@references/changelog-standards.md` | Checking Keep a Changelog 1.1.0 categories, SemVer rules, Conventional Commits mapping, or compare URL formats |
| `@references/project-archetypes.md` | Adapting changelog sections for libraries/SDKs, CLIs/dotfiles, services/web apps, monorepos, or security-sensitive repos |
| `@references/provenance-recording.md` | Writing or validating `changelog-provenance` YAML blocks, omission ledgers, and optional collapsible audit trails |
| `@references/audit-methodology.md` | Evaluating the five audit dimensions (format, provenance, continuity, reconciliation, SemVer) and finding severities |
| `@references/gap-detection.md` | Triaging user-visible vs. internal commits, squash vs. merge commits, cherry-picks, or monorepo path filters |

## Templates

| Archetype / Output | Path | Purpose |
|---|---|---|
| **Keep a Changelog** | `templates/changelog-keepachangelog.md` | Standard layout with `[Unreleased]`, version sections, and provenance block |
| **Library / SDK** | `templates/changelog-library-semver.md` | SemVer layout highlighting `Breaking Changes`, migration guides, and API contracts |
| **CLI & Tooling** | `templates/changelog-cli-tool.md` | Commands, subcommands, flags, environment variables, and OS matrix |
| **Service & Web App** | `templates/changelog-service-webapp.md` | Release trains, user features, schema migrations, and operational notes |
| **Monorepo** | `templates/changelog-monorepo.md` | Multi-package workspace layout with package scopes and shared tooling |
| **Audit Report** | `templates/changelog-audit-report.md` | Formal audit report with executive summary, missing commits table, and checklist |

## Bundled Scripts

Run scripts relative to this skill directory (`<skill-dir>/scripts/...`):

| Script | Location | Run When |
|---|---|---|
| `create-changelog.py` | `@scripts/create-changelog.py` | Initializing a new `CHANGELOG.md` from one of the 5 changelog templates |
| `extract-git-history.py` | `@scripts/extract-git-history.py` | Gathering commits, PR numbers/labels, grouped draft entries, and `changelog-provenance` across a git range |
| `audit-changelog.py` | `@scripts/audit-changelog.py` | Verifying `CHANGELOG.md` against git history, range continuity, provenance, and strict CI gates |

```bash
# 1. Scaffold a new CHANGELOG.md (templates: keepachangelog, library, cli, service, monorepo)
python3 <skill-dir>/scripts/create-changelog.py --template cli --repo warpcode/dotfiles

# 2. Gather git history & provenance JSON (or Markdown draft) from latest tag to HEAD
python3 <skill-dir>/scripts/extract-git-history.py --version 1.3.0
python3 <skill-dir>/scripts/extract-git-history.py --from-ref v1.2.0 --to-ref HEAD --no-gh --json

# 3. Audit an existing CHANGELOG.md (use --strict for CI gate, --report for Markdown output)
python3 <skill-dir>/scripts/audit-changelog.py
python3 <skill-dir>/scripts/audit-changelog.py --version 1.2.0 --report docs/changelog-audit-report.md --strict
```

## Workflows

### Authoring Workflow (Gather -> Categorize -> Publish)
1. **Gather**: Run `@scripts/extract-git-history.py` (or `@scripts/create-changelog.py` for a new file) to establish the exact `<base>..<head>` commit window, PR numbers, labels, and candidate omission ledger in one snapshot.
2. **Categorize & Align**: Refine human-facing descriptions per `@references/changelog-standards.md` and `@references/project-archetypes.md`, ensuring breaking changes, migrations, and security advisories sit in the right SemVer sections.
3. **Publish**: Insert the release section under `[Unreleased]`, keep the `changelog-provenance` YAML block and bottom compare URLs accurate per `@references/provenance-recording.md`, then verify with `@scripts/audit-changelog.py --strict`.

### Auditing Workflow (Audit -> Triage -> Remediate)
1. **Audit**: Run `@scripts/audit-changelog.py` (add `--path` for monorepos, `--version` for a single release, or `--json` for structured findings) to check format, provenance completeness, range continuity, and unaccounted commits.
2. **Triage**: Classify flagged commits against `@references/audit-methodology.md` and `@references/gap-detection.md` into user-facing omissions (`High` / `Critical`) vs. internal chores (`Low`).
3. **Remediate**: Update the release narrative with missing user-facing PRs/links or append verified internal commits to `omitted_or_internal`, and re-run `@scripts/audit-changelog.py --strict` (optionally emitting `templates/changelog-audit-report.md` via `--report`).
