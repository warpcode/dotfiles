# Code Review Rubrics & Verification Techniques

Domain reference for defect prioritization, premise scrutiny, mutation verification, CI coverage auditing, and benchmark validation.

---

## 1. Audit Prioritization Hierarchy

Evaluate changes systematically in descending priority order:

1. **Bugs and functional correctness** (logic errors, race conditions, boundary failures, nil/null handling).
2. **Security issues** (injection, SSRF, auth/authz bypasses, secret leakage, unsafe deserialization — pair with `code-security-audit`).
3. **Leftover test/debug code and test data** (debug prints, `set -x`, commented-out blocks, hardcoded dummy values, stray fixture files, auth/validation bypasses in production paths).
4. **Style guideline violations** (load language-specific instruction/style skills where applicable).
5. **Performance and efficiency** (N+1 queries, unbounded reads, redundant subprocess calls, hot-path allocations).
6. **Readability and maintainability** (excessive nesting, duplicated logic, unclear naming).
7. **Anti-patterns and duplication** (reimplementing existing repo helpers or diverging from established abstractions).
8. **Project convention consistency** (flag standardization, error formatting, config layering).
9. **Issue requirement compliance** (completeness against source ticket acceptance criteria and edge cases).
10. **Unresolved PR comments and review questions** (open threads from earlier review rounds).

---

## 2. Premise Validity & Superseded Changes

Never assume a PR's stated problem or proposed fix is valid simply because the PR exists or tests pass locally:

- **Verify the Underlying Premise**: Confirm the alleged defect or format constraint actually exists in the codebase and fixtures. Watch for fabricated domain assumptions (e.g., claiming a parser supports multiple delimiters when existing callers and fixtures use one) and check all call sites for consistency.
- **Scope & Utility**: Flag superficial churn, redundant wrappers, or unrequested refactors unrelated to the linked issue.
- **Superseded Sibling PRs**: If the target defect was already resolved by a recent commit on the base branch, mark the PR as superseded rather than drafting line-by-line review findings.
- **Merge Regression Check**: When a PR ends in a merge or rebase commit, diff modified files against their base-branch versions to verify formatting, fixture whitespace, and trailing newlines were not regressed.

---

## 3. Test-Only Changes & Mutation Verification

When a diff adds or modifies tests without changing production behavior, "all N tests pass" is not proof of coverage:

1. **Run `scripts/mutation_check.sh` (Never Hand-Roll)**:
   - Write a JSON mutation spec (`[{"name": "...", "path": "...", "old": "...", "new": "...", "count": 1}]`).
   - Run `python3 <skill-dir>/scripts/apply_mutation.py --check --root <head-dir> <spec.json>` first to verify every multi-line `old` pattern matches exact physical indentation. Exit code `1`/`2` indicates a spec mismatch, not a code finding.
   - Execute `bash <skill-dir>/scripts/mutation_check.sh --pr <n> --spec <spec.json> --test-cmd "<whole-package-cmd>"`.
2. **Whole-Package Scope**: Always pass the **whole-package** test command to `--test-cmd`, never a `-run` filter restricted to newly added subtests — sibling tests in the same package frequently cover the branch.
3. **Head vs. Base Verdict Interpretation**:
   - `KILLED`: Named test(s) fail on head (and did not fail on base) -> branch is covered.
   - `SURVIVED`: No test fails on head -> actionable finding; quote the mutation and target test file.
   - `PRE-EXISTING`: Base branch fails too -> pre-existing repo-wide gap, not introduced by this PR.
4. **Shadowed-Guard Detection**: Verify a failing subtest actually exercises the mutated guard rather than an unrelated downstream fallback producing the same output. Read the failing test names and assertions.
5. **Injection-Test Payload Hygiene**: In shell/Python command-injection tests, pass untrusted payloads via environment variables or temp files rather than directly inside `-c` or heredoc script strings, so command substitutions are not evaluated during test parse time.

---

## 4. CI Coverage & Benchmark Verification

- **Verify "Tests Pass" Claims Against CI**: Run `bash <skill-dir>/scripts/audit_ci_test_coverage.sh --repo <owner>/<repo> [--ref <base-ref>] [test/path ...]` to check whether any `.github/workflows/*.yml` job actually discovers and executes the tests, and whether `paths:` filters skip the workflow for the PR's changed file extensions. Flag unexecuted tests and unverified test claims.
- **Benchmark & Performance Claims**:
  - Confirm any cited benchmark or test function is actually committed to the PR head blob (not local-only).
  - Re-run cited benchmarks on both head and base in isolated worktrees (`github-pr/scripts/review_worktree.sh`) to verify headline deltas exceed measurement noise.
  - Confirm the benchmark actually exercises the changed code path before accepting reported numbers.
