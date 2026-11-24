# Test & Mutation Verification Guidelines

Standards for proving that test changes genuinely exercise production branches, auditing CI test coverage, and avoiding shell-parse pitfalls in injection tests.

---

## 1. Test-Only Diff Scrutiny

When a diff modifies only test files without touching production code, "all N tests pass" is not evidence of coverage. Spend review effort proving the tests are meaningful:
- **Assertion Strength**: Inspect what assertions actually check. Length-only checks, existence-only checks, or values asserted nowhere are high-yield findings.
- **Branch Coverage**: Grep the whole package for the target branch to distinguish "this change's gap" from a "repo-wide gap."
- **Downstream Shadowing**: Verify a subtest whose name implies a specific guard actually fails when *that* guard is broken rather than passing because a downstream fallback produces identical output.

---

## 2. Mutation Verification (`scripts/mutation_check.sh` & `scripts/apply_mutation.py`)

Prove assertions bite by mutating one branch of the code under test and confirming a *named* test or subtest fails. Never hand-roll ad-hoc shell `run_mut` functions or inline Python source rewriters.

### Core Rules
1. **Run the whole package, never a filtered `-run` subset**: A filtered test run often reports an "uncovered gap" that a sibling test in the same package already catches. Always pass the whole-package command to `--test-cmd`.
2. **Compare against the base branch**: Run the same mutation against base to distinguish new gaps (`SURVIVED`) from pre-existing repo-wide gaps (`PRE-EXISTING`, at most a follow-up issue) and covered branches (`KILLED`). `--skip-base` forfeits the `PRE-EXISTING` distinction.
3. **Report surviving mutations with named evidence**: A `SURVIVED` verdict is an actionable finding—quote the mutation and the test file that should have caught it. A `KILLED` verdict records which named test caught it.
4. **Never report an unapplied pattern as a gap**: Exit `2` means the `old` text did not match verbatim (commonly caused by miscounting physical indentation in nested blocks). Treat `pattern not found` as a spec bug to fix, never as evidence about the code.

### Workflow
1. Pre-validate the mutation spec JSON array against the target root so indentation and occurrence counts are verified before running tests:
   ```bash
   python3 <skills-dir>/code-review/scripts/apply_mutation.py --check --root <head-dir> <mutations.json>
   ```
2. Run mutation verification against PR head and base worktrees:
   ```bash
   bash <skills-dir>/code-review/scripts/mutation_check.sh \
     --pr <n> --spec <mutations.json> --test-cmd "<whole-package-test-cmd>"
   ```

Spec format (JSON array; `"new": ""` deletes matched text, `"count"` defaults to `1`):
```json
[
  {
    "name": "M1: drop empty-key guard",
    "path": "pkg/guard.go",
    "old": "if key == \"\" {",
    "new": "if false {"
  }
]
```

---

## 3. CI Test Coverage Audit (`scripts/audit_ci_test_coverage.sh`)

Never take "all tests pass" or "verified with `unittest`" claims at face value if CI does not discover or trigger those test files:
```bash
bash <skills-dir>/code-review/scripts/audit_ci_test_coverage.sh \
  --repo <owner>/<repo> [--ref origin/master] [test/path ...]
```
- Reports detected test files on the ref, test-runner invocations in `.github/workflows/*.yml`, and `paths:` filters that can skip CI on partial diffs.
- Treat `NO test file is named in any workflow` as grounds to flag test-verification claims as **unconfirmed** and newly added tests as never executed by CI.
- Reproduce a newly added test's pass/fail behavior locally in an isolated worktree before trusting a green CI check.

---

## 4. Injection-Test Payload Hygiene

Shell-injection regression tests must pass payloads as **data** (environment variable or temp file), never embedded inside `-c` or heredoc script text:
- `subprocess.run([shell, "-c", f"... $(touch {marker}) ..."])` executes command substitution during **parse** of the `-c` string before the code under test runs, causing the marker to always be created (or hiding broken assertions if inverted).
- Always run reproduction tests out-of-tree (e.g., `/tmp/`) and pass untrusted payloads via environment variables or temp files so the wrapper script itself contains no `$(...)` expansion.
