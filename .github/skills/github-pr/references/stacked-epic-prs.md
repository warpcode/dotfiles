# Stacked & Epic-Tree Pull Requests

Guide for structuring, targeting, retargeting, rebasing, and merging pull requests across mainline, epic integration branches, and stacked dependency chains.

---

## 1. Targeting Models & `baseRefName`

Never assume a PR targets `main` or `master`. Determine `baseRefName` explicitly from user direction, epic metadata, or PR state:

| Model | Target `baseRefName` | When to Use |
|---|---|---|
| **Mainline PR** | Default branch (`main` / `master`) | Standalone features, fixes, or chores ready to land directly on trunk |
| **Epic Integration PR** | `epic/<id>-<slug>` | Large multi-task initiatives (5+ PRs) landing incrementally into an integration branch before a single epic merge to trunk |
| **Stacked PR Layer** | Upstream dependency branch (`feat/layer-k`) | Linear dependency chains where layer `k+1` builds on unmerged layer `k` |

### Creating & Inspecting Targeted PRs

```bash
# Always create as draft targeting the explicit baseRefName
gh pr create --repo <owner>/<repo> --draft --base <baseRefName> --title "..." --body-file pr_body.md

# Query current target base dynamically
gh pr view <n> --repo <owner>/<repo> --json baseRefName,headRefName,state
```

---

## 2. Retargeting `baseRefName` When Upstream PRs Merge

When an upstream PR in a stack (or an epic integration branch) merges or closes, dependent PRs must be retargeted cleanly so they do not merge into a stale/deleted branch or replay already-squashed commits:

1. **Retarget on GitHub**:
   ```bash
   gh pr edit <child-pr> --repo <owner>/<repo> --base <new-base-branch>
   ```
   (For example, retarget layer-2 from `feat/layer-1` to `master`, or to the new upstream branch.)
2. **Replay onto the New Base (`--onto`)**:
   If layer-1 was squash-merged into trunk, a plain `git rebase origin/<new-base>` can re-apply layer-1's original commits and produce duplicate conflicts. Replay strictly the child layer's unique commits:
   ```bash
   git fetch origin
   git rebase --onto origin/<new-base> <old-upstream-tip> <child-branch>
   ```
   Verify the resulting diff against `origin/<new-base>` contains only the child layer's changes, run local tests/validation, and push after approval.

*(For automated stack cascading via the `gh stack` extension, see `github-cli/references/stacked-prs.md`.)*

---

## 3. Stack Architecture & Layer Ordering

```text
(trunk or epic/<id>-slug) <- layer-1 (bottom) <- layer-2 (middle) <- layer-3 (top)
```

- **Plan Layers Upfront**: A stack is a strict dependency chain. Any shared schema, type, or interface required by layer `k` must exist in layer `k` or a lower layer.
- **Bottom-Up Order**:
  1. **Foundation**: ADRs/plans, schemas, core types, shared interfaces, preparatory refactors.
  2. **Core Logic**: Domain services, pipelines, rules consuming the foundation.
  3. **Surface & Teardown**: CLI/UI wiring, integration tests, and removal of deprecated code once all callers in lower layers are migrated.
- **Atomic Layer Compilation**: Every individual PR in the stack must compile and pass tests independently when checked out alone.
- **One Concern per Layer**: Group branches into a stack only when they belong to the same feature or epic; split multi-concern layers.

---

## 4. Maintaining & Merging Stacks

- **Fix in the Owning Layer**: Never patch a lower layer's bug on a top branch. Check out the owning layer, commit there, and cascade-rebase upper layers upward.
- **Enable `rerere`**: Enable `git config rerere.enabled true` so conflict resolutions recorded on lower layers replay automatically as upper layers cascade.
- **CI Branch-Filter Awareness**: When `.github/workflows/*.yml` restricts `pull_request` triggers to `[main]` / `[master]`, mid-stack PRs targeting `epic/<id>-<slug>` or `feat/layer-k` will not run full CI on GitHub until retargeted to trunk. Run the full local validation suite on every rebased layer before pushing.
- **Bottom-Up Merging**: Merge stacked PRs bottom-up (layer-1 -> layer-2 -> ...), retargeting and re-syncing remaining upper layers after each squash-merge.
