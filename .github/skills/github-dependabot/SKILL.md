---
name: github-dependabot
description: >
  Reference hub for Dependabot alert classification, phantom alert dismissal,
  ecosystem lockfile bump patterns, Dependabot PR bot commands, and
  .github/dependabot.yml schemas. Use when triaging Dependabot alerts, bumping
  vulnerable dependencies, reviewing Dependabot PRs, or configuring dependabot.yml.
---

# GitHub Dependabot Reference Hub

Domain reference for classifying Dependabot security alerts, applying ecosystem lockfile upgrades, interacting with `@dependabot` PRs, and configuring `.github/dependabot.yml`.

## Shared Resources

Run bundled helper scripts relative to this skill's root directory (`<skill-dir>/scripts/...`):

| Resource | Location | Invocation Syntax | Purpose |
|---|---|---|---|
| Repo alert audit | `@scripts/audit_repo_alerts.py` | `python3 <skill-dir>/scripts/audit_repo_alerts.py --repo <owner/repo> [--base <default-branch>] [--json] [--fetch]` | Dependabot + code-scanning triage in one call. Classifies each alert against the default branch, separates **phantom** alerts from real ones, flags `first_patched_version: NONE`, and prints dismissal commands. Read-only. |

---

## 1. Alert Classification & Triage Reference

Run `audit_repo_alerts.py --repo <owner/repo> --base <default-branch>` first to obtain a single-snapshot classification:

| Alert Class | Condition on `origin/<default-branch>` | Action |
|---|---|---|
| **Active Vulnerability** | Manifest exists on default branch and `fixed_in` is defined | Upgrade dependency in-tree via ecosystem lockfile recipes below and verify tests |
| **Phantom Alert** | Manifest path is absent from default branch (moved, renamed, deleted, or backup tree) | Dismiss as `inaccurate` via `gh api` (command printed by `audit_repo_alerts.py`) and remove stale manifests from the tree |
| **Unfixable Advisory** | `first_patched_version: NONE` | Record GHSA ID in tracking issue and re-audit periodically; do not open empty churn PRs |

### Dismissal API Constraints

- **Endpoint**: `PATCH repos/<owner>/<repo>/dependabot/alerts/<alert_number>` with `-f state=dismissed -f dismissed_reason=inaccurate -f dismissed_comment="..."`
- **Comment Length**: `dismissed_comment` is capped at **280 characters** (GitHub returns HTTP 422 if exceeded).
- **Architecture Boundary**: GitHub's Dependency Graph discovers manifests repo-wide for security alerts; `.github/dependabot.yml` controls automated version-update PRs only.

---

## 2. Ecosystem Lockfile Bump Recipes

Targeted, lockfile-preserving update commands (run local tests, `git diff`, and syntax/compilation checks before committing):

- **Python (`uv`)**:
  ```bash
  uv lock -P <package_name>   # single-package bump
  uv lock -U                  # full lockfile upgrade
  ```
- **Node.js (`npm` / `pnpm` / `yarn`)**:
  ```bash
  npm update <package_name> --package-lock-only
  pnpm update <package_name>
  yarn upgrade <package_name>
  ```
- **Ruby (`bundler`)**:
  ```bash
  bundle update <package_name> --conservative
  ```
- **Go (`go.mod`)**:
  ```bash
  go get <package_name>@latest && go mod tidy
  ```

---

## 3. Dependabot PR Evaluation & Bot Commands

### Evaluation Signals
- **Compatibility Score**: Check GitHub's compatibility badge in the Dependabot PR body.
- **Release Notes**: Inspect linked changelogs for breaking changes across major/minor bumps.
- **CI Status**: Verify all required workflows pass on the PR branch.

### `@dependabot` PR Comment Commands
- `@dependabot rebase` — rebase against the target branch.
- `@dependabot recreate` — recreate the PR and lockfiles from scratch.
- `@dependabot ignore this package version` — suppress PRs for this specific version.
- `@dependabot ignore this dependency` — suppress future PRs for this dependency.
- **Merging**: `@dependabot merge` is deprecated; use `gh pr merge <pr_number> --repo <owner/repo> --squash --auto` (or `github-pr/scripts/pr_merge.sh`).

---

## 4. `.github/dependabot.yml` Schema & Patterns

```yaml
version: 2
updates:
  - package-ecosystem: "pip" # or "uv" / "poetry" / "npm" / "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

- **Pin `directory:`**: Explicitly target live manifest directories so automated PRs do not target stale or backup paths.
- **Group Minor/Patch Updates**: Use `groups:` for non-breaking updates to reduce PR noise.
- **Cap Concurrency**: Set `open-pull-requests-limit` per ecosystem to avoid PR saturation.
