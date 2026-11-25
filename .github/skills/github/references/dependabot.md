# GitHub Dependabot Reference

Domain reference for classifying Dependabot security alerts, applying ecosystem lockfile upgrades, interacting with `@dependabot` PRs, and configuring `.github/dependabot.yml`.

---

## 1. Alert Classification & Triage

Run `scripts/audit_repo_alerts.py --repo <owner/repo> --base <default-branch>` first to obtain a single-snapshot classification:

| Alert Class | Condition on `origin/<default-branch>` | Action |
|---|---|---|
| **Active Vulnerability** | Manifest exists on default branch and `fixed_in` is defined | Upgrade dependency in-tree via ecosystem lockfile recipes below and verify tests |
| **Phantom Alert** | Manifest path is absent from default branch (moved, renamed, deleted, or backup tree) | Dismiss as `inaccurate` via `gh api` (command printed by `audit_repo_alerts.py`) and remove stale manifests from the tree |
| **Unfixable Advisory** | `first_patched_version: NONE` | Record GHSA ID in tracking issue and re-audit periodically; do not open empty churn PRs |

### Dismissal API & Alert Triage Invariants

- **Endpoint**: `PATCH repos/<owner>/<repo>/dependabot/alerts/<alert_number>` with `-f state=dismissed -f dismissed_reason=inaccurate -f dismissed_comment="..."`
- **Comment Length**: `dismissed_comment` is capped at **280 characters** (GitHub returns HTTP 422 if exceeded). Valid code-scanning `dismissed_reason` values are `false positive`, `won't fix`, `used in tests`, and `mitigated`.
- **Architecture Boundary**: GitHub's Dependency Graph discovers manifests repo-wide for security alerts; `.github/dependabot.yml` controls automated version-update PRs only. Pinning `directory:` and deleting stale/backup manifests prevents recurring phantom alerts.
- **Zsh Loop Hazard**: Never bind a shell loop variable to `path` in zsh (`path` is tied to `PATH`, stripping `git`/`gh` from `PATH` and falsely reporting every manifest as absent). Use `scripts/audit_repo_alerts.py` in Python instead.
- **CodeQL False Positives**: A `py/command-line-injection` finding on `subprocess.run(cmd, ...)` is usually a false positive when `cmd` is an argv list; check for `shell=True`, `os.system`, `subprocess.call`, or `Popen` before treating it as real.

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
- **Merging**: `@dependabot merge` is deprecated; use `gh pr merge <pr_number> --repo <owner/repo> --squash --auto` (or `scripts/pr_merge.sh`).

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
