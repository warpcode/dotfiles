---
name: github-pr-review
description: Master orchestrator for end-to-end GitHub pull request reviews (discovery, audit, and submission). Use when managing a formal PR review from candidate selection through findings and submission.
---

# PR Review Orchestrator

Master orchestrator for pull request reviews. You are responsible for the entire review lifecycle, delegating specialized audits to subagents and ensuring project memories are updated after every review.

## 🧰 Script Reference

**Prefer a bundled script over a hand-rolled command chain.** Every script below
emits a concise Markdown summary to stdout, so one call replaces a dozen bash
calls. `--help` documents each one. Paths are relative to this skill's directory.

| Script | Use it for |
| --- | --- |
| `github-cli/scripts/pr_audit_bundle.sh` | **First call of any audit.** Writes `meta.json`, the full diff, head copies of every changed file and the source issue, then prints a summary. Replaces separate `gh pr view` / `gh issue view` / `gh pr diff` calls. |
| `scripts/pr_preflight.sh` | Captures the diff and the head ref from **one fetch** and asserts the head has not moved. Exit 3 = the PR was amended mid-audit; re-run before submitting. |
| `scripts/review_worktree.sh` | Creates, lists and destroys throwaway audit worktrees under fixed names (`pr<n>-head`, `pr<n>-base`). Fetches the PR ref on demand; `rm --all-roles` tears a PR's set down in one call. |
| `scripts/mutation_check.sh` | Proves a test suite actually bites. Applies each mutation, runs the test command over the **whole package** on both head and base, and reports which named test caught it. Verdict per mutation: `KILLED` / `SURVIVED` / `PRE-EXISTING`. |
| `scripts/build_review_payload.py` | Turns a findings spec JSON into a REST review payload (inline comments, `side: RIGHT`, no `subject_type`). |
| `scripts/verify_review_anchors.sh` | **Hard gate.** Exits non-zero if any anchor is not an added line, or cannot be resolved against `--head`. |
| `scripts/submit_review.sh` | Builds → verifies → submits, in that order, capturing diff and ref in one fetch. The preferred submission path. |
| `scripts/audit_ci_test_coverage.sh` | Reports whether CI actually runs the repo's tests, and which `paths:` filters gate it. |
| `scripts/apply_mutation.py` | The mutation rewriter `mutation_check.sh` calls. Run it standalone with `--check` to confirm a pattern applies before committing to a finding. |
| `scripts/reply_to_review_thread.sh` | Replies to an unresolved PR review comment thread with the created URL on stdout. |

## 📄 Templates

| Template | Path | Usage |
| --- | --- | --- |
| Inline Review Comment | `@templates/pull_request_review_comment.md` | Required schema for `REQUEST_CHANGES` inline findings (`Severity`, `Description`, `Impact`, `Proposed Solution`). |

## ⚖️ Code Review Orchestration Standards

### Review Tone & Style
- **Tone**: Strictly neutral, fact-based, and formal. Do not include encouraging adjectives, subjective evaluations, or conversational filler (e.g., "looks excellent", "successfully", "elegantly", "LGTM").
- **Format**: For each finding, use the structure: 1. Severity (High/Medium/Low), 2. Description, 3. Impact, 4. Proposed Solution. Refer to `@templates/pull_request_review_comment.md` for comment formatting details.

### Review Events & Decision Rules
- **REQUEST_CHANGES**: Use whenever ANY finding exists, including low-severity findings, unaddressed comments, or unresolved merge conflicts.
- **COMMENT**: Do not use as a substitute for `REQUEST_CHANGES` based on severity. Use only for the self-authored-PR restriction (where GitHub API blocks `REQUEST_CHANGES` on self-authored PRs), or when the user explicitly requests a non-decision comment.
- **APPROVE**: Use strictly when zero findings exist or all previously raised issues are fully resolved.
- **Silent Approvals Invariant**: When approving a PR, NEVER add new file comments or subjective summaries. Pass an empty review body (`--body ""`) and submit no comments.

### Review Orchestration & Phase Separation
- **Formal Review Harness**: Formal pull request reviews SHOULD be performed where available to ensure end-to-end audit, specialized subagents, and memory extraction.
- **Code Review Phase Separation**: During active PR review workflows, treat any user architectural ideas, cleanup requests, or file removal proposals as requested review comments to be submitted to GitHub. Do NOT checkout the branch or perform local workspace edits unless the user explicitly commands a local change or workspace modification.
- **Inline Comments Required for Bot-Authored PRs**: When reviewing PRs authored by automated bots (e.g., Jules), all findings MUST be submitted as inline file comments on specific lines (`side: RIGHT`), not solely in the main review body. Bot authors respond to inline comments; findings in the review body alone are ignored. The main review body should be a neutral, brief summary only.
- **Conflict Commenting**: When requesting changes due to merge conflicts or general findings, always add corresponding inline comments directly to the affected files in the review payload to ensure external integrations and bots detect the required changes.

### Audit Prioritization Hierarchy
Systematically evaluate each area, prioritizing findings in the following order:
1. **Bugs and functional correctness**
2. **Security issues**
3. **Style guideline violations**
4. **Performance and efficiency**
5. **Readability and maintainability**
6. **Anti-patterns and duplication**
7. **Project convention consistency**
8. **Issue requirement compliance**
9. **Unresolved PR comments and review questions**

### General Review & Branch Constraints
- **Branch Dynamism**: PR review workflows and scripts MUST NOT hardcode default branch names (e.g. `origin/master` or `master`). Instead, query the PR metadata dynamically (`baseRefName`) to determine the target base branch.
- **Merge Regression Check**: If the PR has a merge/rebase commit at its tip, diff changed files against their base-branch versions to verify formatting, fixture whitespace, and trailing newlines weren't regressed.
- **Line-Comment Constraint**: Line-level comments MUST be on added lines (`+` lines, `side: RIGHT`) within current PR diff hunks.
- **Findings Outside Diff**: For findings on unchanged lines outside the PR diff hunks, post a file-level comment or include the finding in the main review summary describing the file, line number, and proposed fix.
- **No Base Branch Update Requests**: During PR reviews, NEVER ask the author or bot to update, rebase, or sync the pull request branch with the main/base branch.

## 🚀 Lifecycle Procedure

### 1. Discovery & Selection
- Activate the `github-cli` skill (reviews + pull-requests references).
- Perform discovery of open PRs and active threads.
- **Review Boundaries**: When discovering multiple PRs, strictly limit auditing and commentary to the specific PR(s) selected by the user. Do not proactively audit other candidates in the same turn or session unless explicitly requested. Present candidates to the user and obtain explicit selection for a single PR.
- **Batching Permission**: ALWAYS obtain explicit user permission before processing multiple PRs in one session. Only batch if the user explicitly requests "all", a specific list, or confirms the batching proposal.
- If the user requests multiple PRs, preserve strict boundaries by running them as separate lifecycles in the selected order; never broaden one lifecycle to cover multiple PRs.

### 2. Contextual Audit
- **Resolve owner/repo first**: never assume the owner from the local directory or from a remembered `user/repo`. Run `git remote -v` (or `gh repo view --json nameWithOwner`) and use that `<owner>/<repo>` for every subsequent `gh` call. Verified 2026-09-26: a guessed owner (`exampleuser/cloakenv`) failed with `Could not resolve to a Repository` while the real remote was `warpcode/cloakenv`.
- Use `gh pr view <pr> --repo <owner>/<repo> --json <fields>` and `gh pr diff <pr> --repo <owner>/<repo>` to retrieve the PR state without checking out the branch.
- **Scratch Directory Location**: NEVER create or write to `./scratch/` in the active workspace tree. Always write temporary diffs, review payloads, and scratch files to `/tmp/` or the conversation artifact directory (`<appDataDir>/brain/<conversation-id>/scratch/`).
- **Isolate the real diff with a blob-hash sweep (do this first)**: `gh pr diff` is merge-base-relative, so a branch cut before several merges reports files that `main` already contains verbatim. Comparing blob hashes per file collapses the diff to what actually changed, and a `SAME` production file is immediate evidence of a self-reverting refactor or an already-merged change:
  ```bash
  git fetch origin pull/<pr>/head:refs/remotes/origin/pr-<pr> --force
  for f in $(git diff --name-only $(git merge-base origin/main origin/pr-<pr>) origin/pr-<pr>); do
    a=$(git show origin/main:$f 2>/dev/null | git hash-object --stdin)
    b=$(git show origin/pr-<pr>:$f | git hash-object --stdin)
    [ "$a" = "$b" ] && echo "SAME    $f" || echo "DIFFERS $f"
  done
  ```
  - **Self-Reverting Refactors**: A refactor commit can be silently reverted by a *later* commit in the same branch, leaving a PR titled "Refactor X" that ships no refactor — observed on warpcode/cloakenv#191, where `d3be77d` extracted `appendGroup`/`tryExpandBraced`/`tryExpandUnbraced` from `expandTemplate` and `323a54d` then reverted all of it (and deleted the accompanying characterization test). Detect this by blob-hashing the production file at three points:
    ```bash
    git show <refactor-sha>:<path> | git hash-object --stdin      # refactor commit
    git show origin/pr-<n>:<path> | git hash-object --stdin      # head
    git show origin/main:<path> | git hash-object --stdin         # base
    ```
    `head == main` while the refactor commit differs proves the revert. Confirm added files are absent (`git ls-tree origin/pr-<n> <dir> | grep <name>`) and claimed helper symbols appear on neither head nor base (`git grep -c 'func <helper>' origin/pr-<n>`). When unrevised, demand restoring the refactor or retitling and rewriting the PR.
  Verified 2026-10-01: on warpcode/cloakenv#193 this shrank a reported 7-file / +215/-13 diff to **3 genuinely changed files** (`keepass.go`, `keepass_test.go`, `keepass_benchmark_test.go`); the other four, including a whole `AGENTS.md` rewrite, were byte-identical to `main` because they had already landed via #189/#192. On #191 the same sweep showed the *only* non-test file was a filler `dummy.txt`. Read `AGENTS.md` in the reported diff with this in mind — bot-added memory sections are often already on `main`.
- **Superseded Sibling PRs**: If the PR targets a problem already fixed by a recently merged PR/commit on the base branch (e.g. concurrent bot sessions targeting the same vulnerability or function), do NOT draft review findings or request changes. Mark the PR as fully superseded and propose closing it immediately with an explanatory comment (`gh pr close <n> --comment "..." --delete-branch`). Requesting changes from a bot on an already-resolved premise generates wasteful bot iteration loops.
- **Mandatory Source Issue & Requirements Verification**: Whenever a PR is linked to or references an issue/ticket (via branch name, PR title, body, `closingIssuesReferences`, or linked Jira tickets):
    - Retrieve the source issue's complete context, description, and acceptance criteria (AC) via `github-cli` or `jira-api`.
    - Scrutinize whether the PR actually and completely fulfills the source issue's requirements and acceptance criteria.
    - Check for missed edge cases, incomplete subtasks, partial fixes, or unprompted scope creep unaligned with the issue.
    - If the PR does not fulfill the ticket requirements, or if the ticket's underlying premise was invalid, flag this as a primary finding and request changes.
- **Universal Scrutiny for Validity & Utility**: Never assume proposed changes are correct, relevant, or useful simply because a PR was opened (whether bot- or human-authored). Rigorously scrutinize:
    - **Premise Validity**: Does the alleged defect/need actually exist in the code, or is it based on a false premise or hallucination?
      - *Fabricated Format Assumptions*: A bot may invent a domain fact and build on it. Observed on warpcode/cloakenv#203, which changed the tag delimiter to `strings.IndexAny(s, ",;")` on the stated premise that "KeePass tag strings can use both commas and semicolons as delimiters" — the repository's tag parser split on commas exclusively, and no fixture used semicolons. Verify claimed domain facts against existing implementations and fixtures rather than PR descriptions; check consistency across all call sites.
    - **Relevance & Scope**: Is the change relevant and appropriately scoped to the repository and task?
    - **Genuine Utility**: Does the change deliver concrete value, or is it superficial churn, redundant abstractions, or unnecessary refactoring?
- Analyze the diff for functional correctness, security, and conventions.
- For independent coverage, load `code-review` and `code-security-audit` before synthesizing findings; verify every proposed anchor against the PR diff.
- **Large-PR Delegation**: For diffs beyond ~500 lines or >5 files, skip loading those skills into the main context; instead launch two parallel `general` subagents (functional/conventions + security) with a shared evidence protocol: strictly read-only, head evidence via `git show origin/pr-<n>:<path>` (fetch first with `git fetch origin pull/<n>/head:refs/remotes/origin/pr-<n>`), never trust the dirty workspace tree, return findings as `SEVERITY | file:line | Description | Impact | Solution` plus an explicit verdict table (FIXED/PARTIAL/STILL PRESENT) for every unresolved review thread.
- **User-Directed Delegation**: The size threshold is a default, not a prohibition. When the user explicitly requests subagent coverage, launch the same two read-only functional/conventions and security audits even for smaller PRs.
- **Worktree Lifecycle**: Never hand-roll `git worktree add` / `remove` chains. Use `scripts/review_worktree.sh` (`add` / `rm --all-roles` / `list` / `exec`), which assigns one fixed path per role, records what it created, and tears down the whole set in one call. Verified 2026-10-07 across a 4-PR session: 12 worktrees were created under 12 ad-hoc names (`wt214`, `wt214base`, `wt214n`, `wt214prev`, `wt200`, `wt200base`, `wt200prev`, `wt215`, `wt209`, `wt209m`, `wtmerge`, `wtverify`), with no registry, followed by a retyped 11-line `git worktree remove` chain — precisely the three failure modes that script's docstring exists to prevent.
- **Submission**: Use `scripts/submit_review.sh`, which runs build → hard-gate → submit with the diff and head ref captured in a *single* fetch. Do not hand-run `build_review_payload.py` + `verify_review_anchors.sh` + `gh api POST` separately: that separation is what makes a stale-blob race possible, since the verifier can compare a fresh `gh pr diff` against a `--head` ref fetched earlier. Verified 2026-10-07 on all four PRs of a session, each submitted via the manual three-step path.
- **Multi-PR Parallel Subagent Reviews**: When the user requests review of multiple PRs simultaneously, define a single reusable `pr-reviewer` subagent type and invoke one instance per PR in a single `invoke_subagent` call. Each subagent must comply with these non-negotiable safety constraints:
  1. **Diff-only line anchoring**: Subagents MUST NOT read local workspace files (via `view_file` or `cat`) to determine comment line numbers. The local workspace is on `main`, not the PR branch — workspace line numbers are meaningless. All `line` values in review comments MUST be derived exclusively from `gh pr diff <PR>` (the `+`-prefixed lines in the unified diff output).
  2. **Direct payload construction**: Subagents MUST write the review JSON payload directly using `write_to_file` into `/tmp/pr_<PR>_review.json` (or use the bundled `build_review_payload.py` script). Never write or execute ad-hoc Python builder scripts — the sandbox blocks inline Python and custom script execution frequently triggers permission prompts, causing delays.
  3. **Pre-report anchor verification**: Before reporting back, subagents must self-verify each `line` value against `gh pr diff` and confirm it appears on a `+` line within a hunk. A comment on a context or deleted line — or outside the hunk's range — causes HTTP 422 (`Line could not be resolved`) on submission.
- **Competing Open PRs From The Same Bot (check before auditing the diff)**: When several open PRs come from one bot (Jules routinely opens 2-3 at once on the same task class), a PR is frequently a **duplicate of a sibling PR** rather than new work. This is the highest-yield check in the whole audit and is invisible from the diff alone. Observed 2026-10-01 on warpcode/dotfiles: PRs #141 and #143 both optimized the same 30-line `_flatten_adf_list` function in `jira/formatters.py`, from the same merge-base, by the same bot.
    - **Use the bundled detector instead of hand-rolling the loop.** `git-expert/scripts/audit_repo_branches.py` maps every branch to its PR, computes per-file blob differences against the base branch, and reports sibling pairs that share files with a `merge-tree` conflict count — one call instead of three hand-written passes. Run it *before* reading any diff:
      ```bash
      python3 <skills-dir>/git-expert/scripts/audit_repo_branches.py --repo <owner>/<repo>
      ```
      Read the `Sibling conflicts` table. Judge each candidate on its own merits afterwards.
    - Manual fallback:
    ```bash
    gh pr list --repo <owner>/<repo> --state open --json number,title,files -q '.[] | "\(.number) \(.files|map(.path)|join(","))"'
    git fetch origin pull/<n>/head:refs/remotes/origin/pr-<n> pull/<m>/head:refs/remotes/origin/pr-<m>
    git merge-base origin/pr-<n> origin/pr-<m>
    git merge-tree <mb> origin/pr-<n> origin/pr-<m> | grep -c '<<<<<<<'   # >0 = textual conflict
    ```
    - A non-zero conflict count means **only one can merge** and the second will partially revert the first. That is a legitimate **blocking** finding: ask for one to be closed rather than reviewing the diff line-by-line as if it were the only change.
    - **A conflict count can change after an amendment.** Observed 2026-10-03 on warpcode/dotfiles: #143 vs #141 fell from **6 conflict markers to 1** once both bots amended, and the pair went from "duplicates, close one" to "complementary, merge both" — #141 supplied the trustworthy benchmark harness and the missing CI job, #143 the `isinstance` type-safety hardening. Never carry a conflict count across an amendment; re-run it.
    - Weigh the candidates before recommending which survives: prefer the one with more commits, review feedback already applied, `CHANGES_REQUESTED` with threads being worked, and the structurally superior design (e.g. #141 split dispatch into `_flatten_adf_node` + a list wrapper and froze the old implementation as a benchmark baseline; #143 patched in place).
    - **Verify each benchmark baseline against the real pre-change code before trusting any performance claim.** #143's benchmark compared against a hand-rewritten string-returning implementation whose docstring falsely claimed the original had no accumulator; master's `_flatten_adf_list` threads a `parts` accumulator. Re-measured against the real code the change was ~-2% (no speedup). `git show <ref>:<path> | diff - <base-path>` settles it.
    - Watch for the amendment drift: an amendment pushed in response to review can move a PR *away* from its sibling's design rather than toward it. Re-run `git merge-tree` after any amendment rather than assuming the conflict state carried over.
- **Semantic Merge & Base Drift**: Check whether package helpers or functions invoked by the PR branch had their signatures or contracts modified on the base branch (`main`) since the PR was branched. Git often marks additions textually mergeable even when function signatures conflict at compile time.
    - **Same-Path Both-Sides Add**: When the PR adds a new file, verify the path does not already exist on `main`: `git fetch origin pull/<pr>/head:refs/remotes/origin/pr-<pr>`, then `git merge-base origin/main origin/pr-<pr>` and `git ls-tree origin/main <path>`. GitHub's `changeType: ADDED` is merge-base-relative — a file added on **both** sides yields `mergeable: CONFLICTING` and duplicate top-level symbols (e.g. same `Test*` function names) that fail to compile if a resolution keeps both sides. Typical with bot PRs whose premise was already merged via an earlier PR — check whether `main` already covers the claimed gap before evaluating the diff.
    - **CI Absence Check**: `gh run list --repo <owner>/<repo> --branch <head-branch>` (empty = no workflow runs) and `gh api repos/<owner>/<repo>/commits/<sha>/check-suites` (surfaces app-based checks like CodeQL that mask a missing `CI` suite). Flag any "verified" claims in the PR body/commits as unconfirmed when lint/test never ran.
- **Requirements Tracing — field gotcha**: `gh pr view --json linkedIssues` is invalid; use `closingIssuesReferences` (plus `comments`/`body` text) to detect linked issues.
- **One-call audit bundle (run first)**: `bash ~/.gemini/config/skills/github-cli/scripts/pr_audit_bundle.sh --repo <owner>/<repo> --pr <n> --out <scratch>/pr<n>` (run with `BypassSandbox: true`). It writes `meta.json`, the full diff, head copies of every changed file, and the source-issue JSON, then prints a Markdown summary (files, CI, acceptance-criteria checkboxes, dependency status). It replaces the separate `gh pr view` / `gh issue view` / `gh pr diff` calls.
  > ⚠️ **Test and validation execution scope**: The copies under `<scratch>/pr<n>/head/` written by `pr_audit_bundle.sh` contain ONLY modified and added files, not the complete repository. Never run test suites (`pytest`, `python -m unittest`, `go test`) or validation scripts (`validate.py`) inside `<scratch>/pr<n>/head/`. Always run test suites and validation commands inside a complete throwaway worktree created by `review_worktree.sh add --pr <n> --role head` (or use `review_worktree.sh exec --pr <n> --role head -- <cmd>`).
- **Never read a large diff from stdout**: the tool truncates `gh pr diff` output to its tail. Read `pr<n>.diff` and `head/<path>` from the bundle with `view_file` line ranges. Valid `gh api` patterns: `-H "Accept: application/vnd.github.v3.diff" > file` and `-H "Accept: application/vnd.github.raw" > file`; `gh api` has no `--output`, and `--jq` fails on non-JSON responses.
- **Dependency "shipped" check**: when the issue says `depends on #N`, a `CLOSED` state is not proof the dependency shipped (verified 2026-10-03 on warpcode/cloakenv#162: `CLOSED` with an empty `closedByPullRequestsReferences`). Confirm a merged PR exists (the bundle prints it), or that the symbol the PR relies on exists on the base branch.
- **Test-only PRs still need branch-purity evidence**: For a diff that only touches test files (e.g. `_test.go`), there is no production behaviour to reason about, so spend the audit budget on proving the *test* is meaningful:
  - **Mutation-verification**: When a change adds tests without touching production code, "all N subtests pass" is not evidence of coverage. Prove assertions bite by breaking one branch of the code under test and confirming a *named* subtest fails. Report which subtest caught it; tests that pass under mutation are tautological.
    > **Do not hand-roll this.** `scripts/mutation_check.sh` already encodes all four rules below. Read its `--help`, write a `mutations.json` spec, run it. A hand-typed `run_mut` helper plus an inline `python3 - <<EOF` source rewriter is the exact pattern that script was written to replace — verified 2026-10-07, where four heredoc mutation rewriters were hand-rolled on #209 and the inline helper **silently miscounted** (`grep -c` against `go test`/`pprof` output returns 0 on "binary file matches"), reporting 0 failures for mutations that broke 7 tests. The whole harness then had to be rewritten before any number was trustworthy.
  - **Run `mutation_check.sh`, never a hand-written `run_mut` shell function.** Doing this by hand meant re-typing an inline `python3 - <<EOF` source rewriter plus a `cp .bak` / restore dance per mutation (four separate re-definitions in one review session alone). Write a mutation spec and call the script:
    ```bash
    bash <skills-dir>/github-pr-review/scripts/mutation_check.sh \
      --pr <n> --spec /tmp/opencode/pr<n>/mutations.json \
      --test-cmd "go test ./internal/engine/ -count=1"
    ```
    Spec format (JSON array; `"new": ""` deletes the matched text, `count` defaults to 1):
    ```json
    [{"name": "M1: drop the gStart<0 guard",
      "path": "internal/engine/autoload.go",
      "old":  "if gStart < 0 ||",
      "new":  "if true ||"}]
    ```
    It prints a table of mutation → verdict → failing test name, and exits `1` when any mutation survived. It creates the head and base worktrees itself and removes them on exit, so it needs no separate `git worktree` calls.
    - **`SURVIVED` is the finding.** No test failed, so that branch is untested. Quote the mutation and the test file that should have caught it.
    - **`PRE-EXISTING` is not a finding on this PR.** The base branch fails too, so the branch was already untested repo-wide — a follow-up issue at most.
    - **Exit 2 means a pattern never applied.** A mutation that did not apply proves nothing; fix the spec's `old` text rather than reporting the branch as a gap. Use `apply_mutation.py --check` to confirm a pattern exists before relying on it.
      > **A multi-line `old`/`new` pattern must reproduce indentation exactly**, and hand-writing it in JSON is where specs go wrong (verified 2026-10-08 on warpcode/dotfiles#173). The most common failure is picking the indentation of the *logical* statement rather than the physical line: an assignment inside a nested `else:` branch needed 16 leading spaces where the spec had 8, so the pattern matched nothing at all. A leading-whitespace miscount is invisible in the JSON string, and reading the diff does not reveal it — `--check` is the only reliable arbiter, and it can run over the whole spec array in one command *before* `mutation_check.sh`: `python3 <skills-dir>/github-pr-review/scripts/apply_mutation.py --check --root <head-copy-dir> spec.json`. Treat every `pattern not found` as a spec bug to fix, not as evidence about the branch.
  - Read assertions, not just their presence. Grep the whole package for the untested branch to distinguish "this PR's gap" from "repo-wide gap". Strength-of-assertion findings (length-only checks, existence-only checks, values asserted nowhere) are the highest-yield category here.
  - **Scope mutation runs to the whole package, not just the functions the PR touches** (verified 2026-10-03 on warpcode/cloakenv#209). A `-run TestFoo*` invocation covering only the PR's own table will report an "uncovered gap" that a sibling test in the same package already closes: #209's body declared double-quote escaping unprotected because disabling `getQuoteContext`'s `quoteDouble` branch gave "zero failures across all 23 tests" (its 8 + 15), while `go test ./internal/engine/ -count=1` fails the pre-existing `TestMatchCommandRule_Security/Double_quoted_template_expansion`. Always pass the **whole-package** command to `--test-cmd`, never one with a `-run` filter, and re-check any "this gap is untested" claim the author makes against the full package.
  - **When a subtest's name implies a specific guard, prove the mutation distinguishes it** (verified 2026-10-03 on warpcode/cloakenv#209). A case named `braced with non-alphanumeric` appeared to cover `isValidGroupNameOrNum`, but neutering that function entirely left the whole package green: the case actually pinned the unknown-reference-stays-literal fallback, because a *second* guard downstream (`findGroupIndex` returning `-1` → `getGroupValue` rejecting `group < 0`) produced identical output. A test only pins a branch if some input makes the branches differ; when a redundant guard shadows it, add an input that would resolve differently without the guard.
  - **Run the same mutation against the base branch too**, so the finding distinguishes "this PR introduced an untested branch" from "the branch was already untested repo-wide" — the former is actionable on this PR, the latter is a follow-up issue at most. `mutation_check.sh` does this by default; `--skip-base` opts out and forfeits the `PRE-EXISTING` verdict.
- **Stacked PRs on unmerged or closed bases** (verified 2026-10-03 on warpcode/cloakenv#212): when `baseRefName` is not the default branch, `gh pr diff` shows only the *incremental* delta over that base, which is not the change that would ship.
  ```bash
  gh pr view <n> --json baseRefName -q .baseRefName          # is it the default branch?
  git fetch -q origin pull/<n>/head:refs/remotes/origin/pr-<n>
  git diff --stat origin/main origin/pr-<n>                  # the real shipping delta
  git ls-tree origin/main <added-file>                       # does the new file exist on the default branch?
  gh pr list --state all --json number,title,state,baseRefName,headRefName \
    -q '.[] | select(.headRefName == "<base>")'
  ```
  - A base branch whose own PR is **CLOSED without merging** means the reviewed diff cannot land as-is and the "new" files are absent from the default branch. #212 was stacked on `tidy/pr-210-regex-key-mapping` (PR #211 closed unmerged; #210/#211 were byte-identical duplicate submissions, both closed): the PR reported 3 files / +438/-97, while `git diff origin/main origin/pr-212` showed **8 files, +1100/-1**. Report the discrepancy and leave disposition to the user — the *No Base Branch Update Requests* constraint still forbids asking the author to rebase.
  - Such PRs often show `mergeable: UNKNOWN` and a single CI job (`Reject empty commit`), because no test/lint/SAST suite ran. Treat every "verified" / "tests pass" claim in the body as unconfirmed and say so explicitly.
- **Uncommitted Benchmark/Test Claims**: When reviewing PRs (especially performance optimizations), verify that named benchmarks or tests cited in the PR description (such as `BenchmarkFilterResultsByExpression` or `TestCustomVault_Coverage`) are actually committed to the head blob rather than remaining local to the author's environment.
  - **Then re-run the cited benchmark on both head and base and compare** — a committed benchmark can still have fabricated numbers (verified 2026-10-03 on warpcode/cloakenv#200). The body claimed `BenchmarkFlattenSearchResults` went 13,005 → 7,011 allocs/op (-46.1%), 480 KB → 432 KB (-10%), 1.45 ms → 0.97 ms (-33%). Measured in two parallel throwaway worktrees (go1.27.1, `-count=6`): **13,005 → 13,004-13005 allocs/op, 480,333 → ~480,334 B/op, ~949 µs → ~933 µs** — allocation-neutral, time within noise. Report the measured table in the finding; a perf PR whose headline numbers do not reproduce should be challenged on the numbers even when the code change is correct.
  - Check whether the benchmark even *exercises* the changed path before accepting any measurement. Also note when the code change cannot explain the claimed delta (e.g. an allocation the diff removed that was not actually allocating under the current Go release).
- **File Lifecycle Check**: If any file is emptied, significantly reduced, or appears obsolete:
    - Invoke the `file-cleaner` subagent to audit its references.
    - Incorporate the subagent's recommendation into your final feedback.

### 3. Outdated Review Thread Triage (Bot-Authored PRs)
When reviewing a bot-authored PR (e.g. Jules) where amendment commits were pushed after a prior review:
- Compare the current diff/files against the thread feedback.
- **Strict Thread Closing**: Resolve ONLY when the change is verified as complete.
- **Unfulfilled Threads**: DO NOT resolve; post a reply describing what remains outstanding.

1. Retrieve review threads:
   ```bash
   bash <skills-dir>/github-cli/scripts/list_pull_request_review_threads.sh --owner <owner> --repo <repo> --pull-number <pr>
   ```
2. For each **unresolved + outdated** thread:
   - **Completed & Verified**: Resolve directly via GraphQL without adding noise comments:
     ```bash
     # Single thread:
     bash <skills-dir>/github-cli/scripts/update_pull_request_review_thread_resolution.sh --thread-id "<thread_id>"
     # Multiple threads in ONE call (batch resolution prevents tool call sprawl):
     bash <skills-dir>/github-cli/scripts/update_pull_request_review_thread_resolution.sh --thread-ids "<id1>,<id2>,<id3>"
     ```
   - **Uncompleted or Broken**: Bump the thread with a contextual reply using the initial comment's REST integer `databaseId`:
     ```bash
     bash <skills-dir>/scripts/reply_to_review_thread.sh --owner <owner> --repo <repo> --pr <pr> --comment-id <databaseId> --body "..."
     ```
   > ⚠️ **Key Invariant**: `--comment-id` in `reply_to_review_thread.sh` requires an **integer REST `databaseId`** (surfaced in `list_pull_request_review_threads.sh` output), NOT the GraphQL node `id` string (such as `PRRC_...`).
   > ⚠️ **Resolve script emits plain text, not JSON** (verified 2026-09-27): `update_pull_request_review_thread_resolution.sh` prints `Thread ID: <id> | Resolved: <bool>` and exits `0` on success — the underlying GraphQL mutation is `resolveReviewThread`, not `updatePullRequestReviewThread`. Wrapping it in a `jq -r '.data.…'` pipeline therefore fails on both counts and yields a **false negative**: a loop over N threads reports every one as `FAILED` while all N resolves actually succeeded (observed on PR #186, 7/7). Do not pipe it to `jq`, and do not re-run a loop that already succeeded — resolution is idempotent but the wasted calls obscure real failures. To check status, re-query the thread list instead.
   > ⚠️ **Token-efficiency**: `reply_to_review_thread.sh` emits only the created comment's `html_url`, keeping context token-efficient.
   > ⚠️ **Thread-count cross-check**: hand-rolled extraction from the threads output silently drops entries (observed 2026-09-25: a 13-unresolved PR surfaced as 12, hiding thread `mAJXt`). Always parse the **full** thread list and filter to unresolved, then reconcile the total against the script's own `**Total Threads**: N (X resolved, Y unresolved)` header before triaging. Parsing belongs in a script file (`scratch/parse_threads.awk`), not an inline one-liner — split on backticks with `split($0, p, "\`")`, since `sub(/^.*\`/, "", x)` is greedy and silently yields an empty match.
   - **Over-claiming non-empty amendments** (verified 2026-09-27): A *non-empty* commit can still fail to contain the fixes it claims — the empty-commit check above passes it. Observed on warpcode/cloakenv#186: `82c352f` was a real `37 insertions / 72 deletions` change whose sole effect was an `os.CreateTemp` → `os.WriteFile` refactor, while its commit message and three inline thread replies claimed a missing-file path fix, two brand-new sub-tests, and strengthened `entry.Title` assertions. **Treat every commit-message claim and every bot thread reply as an unverified claim.** Establish what the amendment actually did, then confirm each claimed item against the head blob:
     ```bash
     git diff <prev-sha>..<head-sha> -- <path> | rg '^[+-]' | rg -v '^(\+\+\+|---)'
     git show origin/pr-<n>:<path> > scratch/<n>_head.go
     rg -n '<claimed symbol or sub-test name>' scratch/<n>_head.go   # empty = claim is false
     ```
     The same reasoning applies to bot-authored PR *bodies* and "verified" claims in commit trailers. When a claim is false, **do not resolve the thread** — post a reply citing the head-blob line number and keep it unresolved, and re-raise the finding as a fresh inline comment anchored to the line that disproves it.
   - **Empty amendments**: Verify every commit pushed since the last review — an amendment with no file changes does not resolve prior feedback. Keep affected threads open and cite the failing check in the new review.
     ```bash
     git fetch origin pull/<pr>/head:refs/remotes/origin/pr-<pr>
     mb=$(git merge-base origin/<base> origin/pr-<pr>)
     for c in $(git rev-list --reverse origin/pr-<pr> ^$mb); do
       git diff --name-status "$c^" "$c" | grep -q . || echo "EMPTY: $(git log -1 --format='%h %ci' $c)"
     done
     ```
     Bot PRs routinely push sequences of empty commits after `CHANGES_REQUESTED`; do not credit them as fixes (observed on warpcode/dotfiles#122: 7 consecutive empty amendments, zero threads addressed).

### 4. Submission
- **Inline Comment Template**: When drafting inline findings for `REQUEST_CHANGES`, every comment body must strictly adhere to `@templates/pull_request_review_comment.md`:
  - **Severity:** High / Medium / Low
  - **Description:** Exact diagnosis of the defect or invariant breach.
  - **Impact:** Functional failure, regression risk, or performance consequence.
  - **Proposed Solution:** Concrete diff or specific remediation steps.
- **One-call submit (preferred)**: `bash <skills-dir>/github-pr-review/scripts/submit_review.sh --spec <findings.json> --owner <owner> --repo <name> --pr <n> [--event REQUEST_CHANGES|COMMENT|APPROVE] [--body TEXT] [--dry-run]`. It runs the three steps below in the only safe order — build the payload, **hard-gate** on `verify_review_anchors.sh`, submit only if the gate passed — and captures the diff and head ref in a *single* fetch so verification cannot compare against a stale blob. Exit codes: `2` = anchors failed, nothing submitted; `3` = submit failed. With zero inline comments the anchor gate is skipped rather than failing (it rejects an empty anchor list).
  - ⚠️ **`--owner` and `--repo` are separate flags — never pass a combined `<owner>/<repo>` to `--repo`** (verified 2026-10-08 on warpcode/dotfiles#173). The script concatenates them itself (`gh pr diff "$PR" --repo "$OWNER/$REPO"`), so `--repo warpcode/dotfiles` expands to `warpcode/warpcode/dotfiles` and dies with `could not fetch diff for #173` — a message that reads like a network or auth fault and sends you debugging `gh` rather than the flag. Note the contrast with the *other* scripts in this skill family: `submit_pull_request_review_payload.sh` and `pr_audit_bundle.sh` genuinely do take `--repo <owner>/<repo>` combined, so the correct form differs between scripts in the same directory. When a `submit_review.sh` fetch step fails, check for a doubled owner segment before anything else.
  - **Omit `--diff` and `--head`.** Passing either one short-circuits the script's own fetch, which is the only thing making the pair consistent. Supply `--diff`/`--head` only when `pr_preflight.sh` captured them in the same step, and even then prefer the plain call — re-fetching and re-verifying costs one network round-trip and removes the whole stale-ref class of bug. `--dry-run` already prints every anchor it would post, so there is no reason to run it repeatedly; run it once to eyeball, then submit once.
- **Manual equivalent**: write findings to a spec JSON (`path`, `line`, `severity`, `title`, `description`, `impact`, `solution`), then run `python3 <skills-dir>/github-pr-review/scripts/build_review_payload.py <spec.json> --out <payload.json>` (see `--help`), which automatically renders comments into the `@templates/pull_request_review_comment.md` structure. Submit with `github-cli/scripts/submit_pull_request_review_payload.sh --repo ... --pull-number <n> --input <payload.json>`. Do not hand-write an ad-hoc throwaway builder script.
- **Bot-authored PRs** (e.g. Jules): 
  - `APPROVE`: Submit with empty body, no inline comments.
  - `REQUEST_CHANGES`: Neutral one-liner body + inline file-level `comments` with findings formatted per `@templates/pull_request_review_comment.md`. Bots only act on inline comments.
  - **Deleted File Anchoring**: Deleted files have no added lines (`side: RIGHT`) in GitHub diff hunks to anchor comments. Bundle any findings for deleted files into an inline comment on an associated modified file (referencing the deleted path in the body).
  - **Jules-owned PRs**: Jules exclusively owns changes to its PR branch. NEVER push any Git or code changes to that branch, including commits or merges. Never merge the base branch into it or tell Jules to do so; that can duplicate existing changes, create conflicts, desynchronize Jules's local checkout, and cause crashes or empty commits. If base-branch drift or conflicts become unmanageable, consider starting a new Jules session from the current PR branch and let Jules own the subsequent changes. This restriction is about updating the PR branch; landing an approved PR into its base via `gh pr merge` remains a separate action under the normal review and approval process.
- **Review decision**: For this user's reviews, submit `REQUEST_CHANGES` for any finding, including low-severity findings; do not substitute `COMMENT` based on severity. Use `APPROVE` only when there are no findings. GitHub's self-authored-PR restriction is the platform-required exception: use `COMMENT` because GitHub rejects both `REQUEST_CHANGES` and `APPROVE` on one's own PR.
- **Self-Authored PR Review Constraint**: GitHub rejects `REQUEST_CHANGES` and `APPROVE` on PRs authored by the authenticated user with HTTP 422 (`Review Can not request changes on your own pull request`). When reviewing a PR where the author login matches the authenticated user, always set `event: "COMMENT"`.
- **NEVER validate a payload with a mutating `gh api` call.** There is no dry-run for `POST /repos/{o}/{r}/pulls/{n}/reviews` — a probe intended to "check" the payload *creates a real PENDING review* (observed 2026-09-25 on warpcode/cloakenv#180, where `POST ... --input /dev/null` produced review `5321342555`). Validate **locally** instead, which is sufficient:
  ```bash
  jq -e '.event' scratch/review_payload.json          # parses, confirms event
  jq -r '.comments[] | "\(.path):\(.line) [\(.side)]"' scratch/review_payload.json
  ```
  If a stray PENDING review is ever created, delete it before continuing:
  ```bash
  gh api --method DELETE repos/<owner>/<repo>/pulls/<n>/reviews/<review_id>
  gh api repos/<owner>/<repo>/pulls/<n>/reviews -q '.[] | select(.state=="PENDING") | .id'   # confirm none remain
  ```
- Present the full review to the user for approval.
- **Validate the payload with `jq`, not `python3 -c`.** One command is enough and avoids the execution gate:
  ```bash
  jq -r '"event: \(.event)\ncomments: \(.comments|length)", (.comments[] | "  \(.path) \(.line) \(.side)")' <payload-file>
  ```
- Write the payload to a scratch JSON file and submit via:
  ```bash
  bash <skills-dir>/github-cli/scripts/submit_pull_request_review_payload.sh --owner <owner> --repo <repo> --pull-number <pr> --input <payload-file>
  ```
  > ⚠️ Note: `create_pull_request_review.sh` in `github-cli` only supports top-level review bodies. For structured reviews with inline line/file comments, use `submit_pull_request_review_payload.sh` as shown above.
- **REST payload gotchas** (all verified 2026-08-29):
  - `subject_type` is GraphQL-only — OMIT it from REST review comments or the API returns 422 (`Field is not defined on DraftPullRequestReviewThread`).
  - **Self-authored PRs reject `REQUEST_CHANGES` and `APPROVE`**: GitHub returns HTTP 422 (`Review Can not request changes on your own pull request`). This is the only platform-required `COMMENT` exception to the user's review preference.
  - Inline comment `line` must be an **added line in the diff** for `side: RIGHT`, measured as the 1-indexed line number in the **target file** in its post-change state (never the line offset within a saved `.diff` patch file). Anchoring to a context/unchanged line or using a `.diff` line number fails with `Line could not be resolved`. For new files any line in the file works; for modified files only `+` lines.
  - `path` must match the PR's diff path exactly.
  - **Pre-submit anchor verification** (mandatory before `REQUEST_CHANGES`/`COMMENT` with inline comments): run the bundled script — it validates every `path`/`line` pair in the payload against the saved diff and exits non-zero if any anchor is not a `+` line.
    ```bash
    bash <skills-dir>/github-pr-review/scripts/verify_review_anchors.sh \
      --diff <pr>.diff --payload <payload-file> --head origin/pr-<n>
    ```
    To enumerate all valid added line numbers from the diff before drafting findings, run:
    ```bash
    bash <skills-dir>/github-pr-review/scripts/verify_review_anchors.sh --diff <pr>.diff --list
    ```
    Use `--path <file> --line <n> [--line <n> ...]` to check anchors ad hoc, and `--quiet` for the verdict only. A `PASS` verdict is a hard prerequisite for submission.
    > ⚠️ **Never hand-transcribe the hunk-parsing awk.** Two failure modes were observed in practice (2026-09-26): (a) transcribing the one-liner from this file and dropping the `$3` field reference makes the script read the *pre*-change hunk start, so every anchor looks invalid; (b) inverting the diff-line ↔ file-line arithmetic when spot-checking. Both produce confident wrong answers. Let the script do it, and cross-check with `--head origin/pr-<n>` which prints the anchored line's actual text from the PR head blob — that output is the ground truth to eyeball before submitting.
    > The `+` branch must compare `cur` **before** incrementing: after the `@@` header and context lines, `cur` holds the line number of the line currently being read, so `cur++` first shifts the test one line late (off-by-one, verified 2026-09-24).
    > ⚠️ **`could not be resolved against <ref>` means the diff and the ref are from different fetches, not that the anchor is wrong.** The verifier reports this distinctly when the path is absent from `--head` (deleted or renamed file, or a stale ref) or the line is past the file's end. An empty added line is a *valid* anchor and does not trigger it. Treat the verdict as "re-run `pr_preflight.sh`", never as "move the line".
- **Verify "tests pass" claims against what CI actually runs** (added 2026-10-01). A PR body's "verified with `python3 -m unittest`" / "all tests pass" is only meaningful if a workflow discovers those files. Many repos have zero test-running jobs, so the claim is unfalsifiable and a *new* test file may be dead weight. Run the bundled auditor rather than hand-grepping workflows:
  ```bash
  bash <skills-dir>/github-pr-review/scripts/audit_ci_test_coverage.sh \
    --repo <owner>/<repo> [--ref origin/master] [test/path ...]
  ```
  It reports test files present on the ref, any test-runner invocation found in `.github/workflows/*.yml`, the `paths:` filters (a PR touching only e.g. `.py` may trigger nothing), and whether each requested test file is referenced by CI. Treat a `NO test file is named in any workflow` verdict as grounds to flag every test-verification claim in the PR as **unconfirmed** — and to flag any newly added test as never-executed.
  > ⚠️ **A security test that is never run is worse than no test**: on `warpcode/dotfiles` (verified 2026-10-01) a PR added an injection regression test that was *guaranteed to fail* if executed, and no workflow ran it — so a green CI signal masked a completely broken test. Always reproduce a new test's pass/fail behaviour yourself before trusting that CI is green.
- **Injection-test payloads must be passed as data, never as script text** (added 2026-10-01). `subprocess.run([zsh, "-c", f'... $(touch {marker}) ...'])` executes the substitution during **parse** of the `-c` string, before the code under test is ever called. The marker is then always created and `assertFalse(os.path.exists(marker))` always fails — or, if the assertion is inverted or absent, the test silently "proves" nothing. Reproduce such tests out-of-tree (`/tmp/opencode`) rather than in the workspace, and pass payloads via an env var or temp file so the `-c`/heredoc text contains no `$( )`.
- **Check for duplicate sibling bot PRs before reviewing** (added 2026-10-01). Concurrent `bolt/*` and `sentinel/*` Jules sessions routinely target the same function and submit byte-identical changes. Compare blobs across sibling PRs rather than reading both diffs:
  ```bash
  for pr in <a> <b>; do git fetch -q origin pull/$pr/head:refs/remotes/origin/pr-$pr; done
  for pr in <a> <b>; do
    printf '#%s ' "$pr"
    git show "origin/pr-$pr:<path>" | git hash-object --stdin
  done
  ```
  Matching hashes mean only one PR can merge; say so in the review body and let the user choose which to close. Observed on 2026-10-01: `get_work_seconds` (#145/#148), `flatten_adf` (#141/#143), and the `registry.zsh` eval fix (#142/#144) were each submitted twice.
    Note: `$3` on a `diff --git` header carries the `a/`-prefixed path — strip `a/` and compare without a `b/` prefix.
    Authoritative cross-check (works for new and modified files alike): `git show origin/pr-<pr>:<path> | grep -n "<anchor text>"` and compare the reported line number.
  - Write payload files directly with file-writing tools instead of spawning Python scripts, avoiding execution gate blocks and quoting errors.
  - Redirect `gh api` output to a scratch file (e.g. `> out.json 2>&1`) — piping to `--jq`/`cat` can hang the terminal in the alternate buffer and the POST never completes.
  - ⚠️ **Keep in-flight review artifacts outside the repo — and re-verify after any wipe.** Observed 2026-10-01 on warpcode/dotfiles#143: `scratch/` was wiped by an external process *between* `jq` validation and the submit call, taking `review_payload_143.json`, the saved `.diff`, and all metadata with it. The submit script then aborted at its `-f` check with a misleading `input file not found`. Nothing was posted (good — the failure was pre-POST), but the audit had to be reconstructed from scratch. Use the pre-approved external dir `/tmp/opencode/` for the payload and saved diff. Keep `scratch/` only for throwaway output.
    > **`/tmp/opencode/` is not durable either.** It was wiped mid-session on 2026-10-07 (warpcode/cloakenv#215), destroying the validated payload and saved `.diff` between `verify_review_anchors.sh` and the submit call — the identical failure mode, one directory over. Treat a vanished artifact as expected rather than exceptional: regenerate `gh pr diff` **and** re-`git fetch` the head ref in one step, rebuild the payload, re-run the anchor gate, then submit. Never assume a payload verified earlier is still on disk, and never treat a missing-file error at submit time as a payload problem.
  - ⚠️ **Re-fetch and re-verify immediately before submit — the PR head can move mid-audit.** Bot PRs amend without warning. Observed 2026-10-01 on warpcode/dotfiles#143: `gh pr view` reported 1 commit / `+17/-5`, and minutes later the bot had pushed `6c813fa` ("address review comments"), rewriting the `attrs` branch (`if attrs:` → `if isinstance(attrs, dict):` plus a nested `if url:`), adding a fourth guard in the `text` branch, and **deleting** `.jules/bolt.md`. Net effect on the audit: one of four drafted comments became obsolete and every anchor after the first hunk shifted.
    - **The diff and the `--head` ref must come from the same fetch.** `verify_review_anchors.sh --head origin/pr-<n>` reads a *local* ref, while the diff comes from `gh pr diff`. If those two come from different moments, the verifier can print old line text for a line number that now holds different content — which reads as a valid cross-check while proving nothing. Let `pr_preflight.sh` do the fetch:
      ```bash
      bash <skills-dir>/github-pr-review/scripts/pr_preflight.sh \
        --repo <owner>/<repo> --pr <pr> --expect-sha <sha-captured-at-discovery>
      ```
      It writes the diff and the ref in one fetch, prints a manifest, and prints the exact `verify_review_anchors.sh` / `submit_review.sh` commands to run next.
    - **Do not pass `--diff`/`--head` to `submit_review.sh` unless you captured them with `pr_preflight.sh` in this same step.** Both flags short-circuit the script's own fetch, which is the only thing guaranteeing the pair is consistent. Supplying them from an earlier fetch reinstates exactly the stale-ref hazard the script exists to prevent — this was the most common submission pattern in real sessions (13 of 13 calls overrode both flags), and each override had to be preceded by a hand-written `git fetch && gh pr diff` chain to make it safe. Prefer plain `submit_review.sh --spec ... --pr <n>`, which re-fetches and re-verifies in one call.
    - **Assert the head SHA is unchanged** from the value captured at discovery (`jq -r .sha`); `pr_preflight.sh --expect-sha` does this and exits `3` when it moved. If it moved, re-run the audit against the new head before submitting — do not assume the amendment addressed your points, and re-check whether any drafted finding was already resolved by it (here the bot self-fixed the `.jules/bolt.md` finding, so that comment had to be dropped).
    - Treat every bot commit-message claim ("address review comments") as an unverified claim: diff the amendment and confirm each item against the head blob before crediting it.

  - ⚠️ **Audit PR *body* claims against the new head, not the copy you first read.** In the same #143 case the body was byte-for-byte unchanged by the amendment and still advertised "56.7% in benchmark" for a benchmark that never reaches 3 of the 4 changed branches. Re-fetch `body` after any amendment and re-check every numeric/verification claim in it.

### 5. Non-Destructive PR Branch Conflict Resolution
When an approved PR has textual or semantic merge conflicts with the default branch (`origin/main` or `origin/master`) following a prior merge, and user approval is granted to resolve conflicts. **Jules-owned PR exception:** Do not use this procedure to update a Jules-owned PR branch: never merge the base branch into it or push any Git or code changes to it. If the PR is out of date or base-branch changes cause too many conflicts, consider starting a new Jules session from the current PR branch and let Jules own the subsequent changes.

For read-only audit worktrees (mutation runs, benchmark comparisons) use
`review_worktree.sh` instead of `git worktree add` — it gives each role a fixed
name, fetches the PR ref on demand, and removes the whole set in one call:

```bash
W=<skills-dir>/github-pr-review/scripts/review_worktree.sh
bash "$W" add --pr <pr> --role head          # -> /tmp/opencode/wt/pr<pr>-head
bash "$W" add --pr <pr> --role base          # -> /tmp/opencode/wt/pr<pr>-base
bash "$W" exec --pr <pr> --role head -- go test ./... -count=1
bash "$W" rm  --pr <pr> --all-roles --force
```

Hand-rolled `git worktree add`/chains produced three failure modes in real
sessions: three different names for "the base branch" in one session, leaked
checkouts when a command between create and remove failed, and a removal that
failed but was read as success. `rm --all-roles` also self-heals the registry,
so a stale row cannot masquerade as a live worktree.

The procedure below is for **resolving conflicts on a branch you may modify**,
which the audit worktrees deliberately do not support:
1. Create an isolated scratch worktree to preserve the main workspace:
   ```bash
   git worktree add scratch/worktree-<pr> -b fix/pr-<pr> origin/<branch>
   ```
2. Merge the default branch into the PR branch non-interactively:
   ```bash
   git -c core.editor=true merge origin/<default-branch>
   ```
3. Resolve conflicting files, run local regression tests in the worktree, and commit the merge:
   ```bash
   git commit -m "Merge branch '<default-branch>' into <branch>"
   ```
4. Push using a standard push (NEVER `--force` or `--force-with-lease`):
   ```bash
   git push origin fix/pr-<pr>:<branch>
   ```
5. Clean up the isolated worktree and branch:
   ```bash
   git worktree remove scratch/worktree-<pr> && git branch -D fix/pr-<pr>
   ```
> ⚠️ **Key Invariant**: Never use `git rebase` or force push to update PR branches. A merge commit pushed to the PR branch is fully supported by GitHub, passes CI, and will be cleanly squashed into a single commit upon squash-merging into `master`.

### 6. Ruleset-Gated PR Merges
On repositories using active GitHub branch rulesets (e.g. enforcing CodeQL or code quality gates) where the user has bypass privileges (`current_user_can_bypass: "always"`), `gh pr merge --squash` may fail with:
> `Pull request is not mergeable: the base branch policy prohibits the merge.`

Once all required CI checks and approving reviews have passed, supply `--admin` to bypass the ruleset gate:
```bash
gh pr merge <pr> --squash --admin
```

Deleting the remote branch is a separate action. Do not request branch deletion
as part of the merge unless the user explicitly approves that deletion.

### 7. Memory Extraction (Optional)
- After a review, identify durable technical context, user corrections, or decisions that may merit recording.
- Present proposed changes to `~/.agents/AGENTS.md` or relevant skills and obtain user approval before writing them.

## 🧠 Constraints
- **Strict Boundaries**: Do not audit PRs the user did not select.
- **No Base Branch Update Requests**: Never ask the PR author or bot to update, rebase, or sync the pull request branch with the main branch during reviews.
- **Non-Invasive**: Do not checkout branches or modify the workspace during the audit phase.
  - **No Workspace Testing**: Do not execute local test runners or build commands in the workspace during non-invasive audits, as they will run against the default branch rather than the PR branch.
- **Token Efficiency**: Use summarized outputs from tools unless raw output is strictly required for debugging.
