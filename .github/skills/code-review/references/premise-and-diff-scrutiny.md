# Premise & Diff Scrutiny Guidelines

Platform-agnostic criteria for validating the underlying premise, scope, requirement fulfillment, and diff integrity of any code change—whether a local diff, branch comparison, stacked PR, or formal pull request.

---

## 1. Universal Scrutiny for Validity & Utility

Never assume proposed changes are correct, relevant, or useful simply because a diff or PR exists (human- or bot-authored).

- **Premise Validity**: Verify that the alleged defect, requirement, or bug actually exists in the code rather than stemming from a false premise or hallucination.
  - *Fabricated Format Assumptions*: Verify claimed domain facts against existing implementations and fixtures rather than descriptions alone (e.g., claiming a delimiter supports both `,` and `;` when the parser splits on `,` exclusively). Check consistency across all call sites.
- **Relevance & Scope**: Verify the change is relevant and appropriately scoped to the repository and task without unrequested scope creep.
- **Genuine Utility**: Confirm the modification delivers concrete value rather than superficial churn, redundant abstractions, or unneeded complexity.

---

## 2. Optional Source Issue & Specification Verification

Tracker links are **optional enrichment**, never a prerequisite for reviewing code.

When a diff, branch, or PR references an issue, ticket, or specification (GitHub issue, Jira ticket, ADR, or plan):
- Retrieve the full issue context, description, and acceptance criteria.
- Verify the implementation completely and accurately satisfies every stated requirement and edge case.
- Check for partial fixes, missed subtasks, or unaligned scope creep.
- **Dependency "Shipped" Check**: When an issue states `depends on #N`, a `CLOSED` state alone does not prove the dependency shipped—verify a merged commit/PR exists or the required symbol is present on the base branch.
- Flag unmet requirements or an invalid underlying ticket premise as primary findings.

---

## 3. Leftover Test & Debug Artifacts

Inspect all added and modified files—especially production paths, configs, and newly added files—for accidentally committed test or debug artifacts:
- Debug statements (`console.log`, `print`, `fmt.Println`, `debugger`, `breakpoint()`, `set -x`), commented-out blocks, or temporary `WIP`/`HACK` overrides.
- Hardcoded test data, dummy/placeholder values, mock responses, or auth/validation bypasses in non-test code.
- Stray scratch files, local output dumps, or unintended test fixtures/seed data committed in the diff.

---

## 4. Diff Integrity & Drift Checks

- **Isolate the Real Diff (Blob-Hash Sweep)**: Merge-base-relative diffs can include files already identical to the target base branch. Compare per-file blob hashes (`git show <base>:<path>` vs `<head>:<path>`) to identify files that actually differ.
- **Self-Reverting Refactors**: A refactor commit can be reverted by a later commit in the same branch while leaving a "Refactor X" title. Compare blob hashes at refactor commit, head, and base (`head == base` while refactor commit differs proves a self-revert), and confirm claimed new helpers/files actually exist at head.
- **Semantic Merge & Base Drift**: Check whether helpers or functions invoked by the branch changed signatures or contracts on the base branch since branching; textual mergeability does not guarantee compile-time compatibility.
- **Same-Path Both-Sides Add**: When a change adds a new file, verify the path does not already exist on the base branch (`git ls-tree <base> <path>`). Duplicate additions cause conflicts or duplicate top-level symbols.
- **Merge Regression Check**: If the branch tip includes a merge/rebase commit, diff changed files against their base versions to ensure formatting, fixture whitespace, and trailing newlines were not regressed.
- **Stacked PRs on Unmerged or Closed Bases**: When comparing against a non-default base branch, check the delta against the default branch (`origin/main` / `origin/master`) as well as the incremental base to see the real shipping change, and verify whether the intermediate base PR is merged or closed unmerged.

---

## 5. File Lifecycle & Dead-Code Checks

When any file is emptied, significantly reduced, or appears obsolete, consult `code-architecture` (`references/dead-code-and-refactoring.md`) to audit static and dynamic references before recommending keep vs. delete.
