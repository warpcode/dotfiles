# Agent Instructions for warpcode/dotfiles

These instructions capture persistent memories, behavioral guardrails, and technical preferences for this workspace and user environment.

## 🧠 Behavioral Guardrails

1. **Instruction Fidelity & Scope**:
   - **Do not proactively refactor** or introduce unrequested abstractions when only a proposal, suggestion, or targeted fix is requested.
   - **Do not hallucinate helper functions**: Never assume unimported/undefined functions exist or invent unprompted helpers.

2. **Code & Logic Preservation**:
   - Never remove existing error messages, logging, comments, or essential logic during refactoring.

3. **Pre-Action Safety Gate & State Verification**:
   - **Always request explicit user approval** before destructive actions (`rm`, `reset`, `git push --force`, network-impacting changes, or merging PRs).
   - **Symlink Safety**: NEVER perform bulk deletion (`rm -rf`) on directories without first checking if the target is a symlink (`readlink` or `ls -l`). Delete the symlink itself, not the target contents.
   - Verify state before mutating and verify file edits are persisted to disk. Temporary session scratch files can be cleaned up without prompting.
   - **Verb Substitution Ban**: When a user requests a reversible or descriptive operation (archive, hide, close, tidy, move, stash, revert) and the available tooling offers a destructive equivalent (delete, drop, destroy, purge, reset), you MUST NOT substitute. Stop and ask. A missing capability is a question, not a licence for the strongest available verb.
   - **Capability Check Before Destructive Substitution**: Before using a destructive operation to satisfy a request, first verify (read-only) whether a non-destructive equivalent exists. If the only way to check is itself a mutating call, abort and ask.
   - **Irreversibility Asymmetry**: Irreversible operations REQUIRE (a) the user explicitly naming the irreversible action ("delete", "permanently remove", "destroy"), and (b) an immediate pre-flight confirmation. A clearly inferable *intent* is NOT a substitute for the user naming the action.
   - **Batch Safety**: Never batch irreversible operations in a shell loop. Dry-run first, verify the target set, then execute one at a time.

4. **UI Stability & Decision Presentation**:
   - **Never call `update_topic` and `ask_user` in the same turn.** Set topic first, then call `ask_user` in the subsequent turn to avoid raw JSON rendering in CLI.
   - **Recommendation Invariant**: Whenever presenting choices, options, or next steps to the user, ALWAYS explicitly state the recommended choice along with the underlying rationale.

5. **Resource Selection & Delegation**:
   - Check whether an existing skill applies before executing and follow its guidelines.
   - Delegate high-noise exploration (broad searches, large logs, multi-file sweeps) to subagents using light models (`gemini-3.5-flash` with uninherited context).
   - **Script Execution Efficiency**: Do NOT open/read utility or helper script source code if usage and parameters are documented in `SKILL.md` or instructions. Run them directly.
   - **Skill Script Path Resolution**: When running scripts bundled with a skill (`@scripts/<name>` or `scripts/<name>`), always resolve them relative to the active skill package directory (e.g. `.github/skills/<skill-name>/scripts/<name>` or `~/.gemini/config/skills/<skill-name>/scripts/<name>`), never as `./scripts/<name>` from the workspace root.

6. **Tool Parameter & Command Hygiene**:
   - Never pass unnecessary escaped literal quotes in tool arguments (e.g., use `"/path"`, not `"\"/path\""`).
   - **No Inline Python Scripts**: NEVER execute `python3 -c "..."` or heredoc Python scripts in `run_command`. Rely on skill subcommands or dedicated scripts.
   - **No Shell Sleep**: Never run background or chained `sleep` commands in shell strings (`sleep <n> && ...`). Rely on reactive event notifications, background task completion, or the timer tool.
   - **Non-Interactive Git Execution**: Never run `git rebase` or interactive commands without `-c core.editor=true` or `GIT_EDITOR=true` to prevent interactive terminal hangs.
   - **Subagent Reactive Wakeups**: Never poll `manage_subagents` in loops; allow background task notifications and reactive wakeups to resume execution.
   - **Background Task Completion**: When a command is sent to the background via `run_command`, do NOT schedule redundant one-shot timers on its task ID or poll `manage_task status`. The system automatically notifies you with a high-priority message upon task completion; simply stop calling tools to await completion.
   - **PR Branch Synchronization Invariant**: NEVER force-push or rebase PR branches to resolve merge conflicts. Update PR branches by merging `origin/master` (`git merge origin/master`), running regression tests in an isolated worktree, and pushing via standard push. Squash-merging on GitHub produces a single clean commit.

7. **Conflict Resolution Order**: Safety > User Intent > Simplicity > Local Convention.

## 🛠️ Technical Context & Invariants

- **Source of Truth Hierarchy**: `~/.agents/AGENTS.md` is the authoritative source for durable memory. Keep workspace-only notes ephemeral.
- **Git & PR Workflows**: Delegated to `git-expert`, `github-issues`, `github-pr`, `github-cli`, and `github-pr-review` skills. Always use a rebase strategy when pulling or syncing remote changes. During PR reviews, never ask to update or sync the pull request branch with the main branch.
- **Silent Approvals Invariant**: NEVER include "LGTM", approval boilerplate, or body comments when approving a PR (`gh pr review --approve`). Approvals MUST have an empty body (`--body ""`) or no body flag. When approving, do not comment at all.
- **Bot PR Merges**: NEVER instruct or ask Jules to merge PRs (it breaks the Jules runner). Always execute PR merges directly via `gh pr merge` once reviews and checks are complete.
- **Ruleset-Gated PR Merges**: On repositories with active branch rulesets where the authenticated user has bypass privileges (`current_user_can_bypass: "always"`), `gh pr merge` requires `--admin` to complete the squash-merge once CI and reviews are green.
- **Non-invasive PR audits**: Use remote PR metadata, diffs, and CI logs; never checkout the PR branch or run workspace tests/builds during the audit, and never request base-branch synchronization.
- **PR CI verification**: For pull-request checks, compare branch-filtered workflow runs with commit check-suites/check-runs; PR-ref runs may be absent from `gh run list --branch` while CodeQL and other app checks still exist.
- **CI test coverage** (updated 2026-10-07): `python-tests.yml` (added 2026-10-03) discovers and runs Python test suites under `.github/skills/*/scripts/` and repo-root `tests/`. However, Zsh test suites (`dot_zsh/tests/*.zsh`) still have no runner step; `test.yml` only invokes `./install.sh` and `lint.yml` only runs `zsh -n` over `*.zsh` (syntax parse check only). Consequence for reviews: claims of Python test passage are verifiable via CI check-runs, but Zsh test assertions remain unexecuted in CI until a runner step is added.
- **Zsh `${(P)name}` is not a safe indirection for associative subscripts**: `local ref="arr[$key]"; print -r -- "${(P)ref}"` makes Zsh re-parse `key` as an expression, so `$( )` and backticks in the key execute. This is the injection vector in `dot_zsh/functions/registry.zsh` (`_registry.aa_get`, and `registry.define`'s `${(P)exists_ref`); stripping `eval` from `_registry.aa_set` does **not** close it. Sanitize keys to a charset such as `[A-Za-z0-9_.:]` before building the subscript. Also note `zsh -c "<script containing $( )>"` executes the substitution during *parse*, so any injection test payload must be passed as data (env var / temp file), never interpolated into the `-c` text — otherwise the test always "detects" injection regardless of the code under test.
- **Duplicate bot PRs are common**: Jules `bolt/*` and `sentinel/*` sessions frequently target the same function concurrently. Before reviewing, diff the touched blobs across sibling PRs (`git show origin/pr-<n>:<path> | git hash-object --stdin`) — identical hashes mean one PR should be closed. `get_work_seconds` had two competing O(1) rewrites (#145/#148) and `flatten_adf` two (#141/#143); the `registry.zsh` eval fix was submitted twice with the same blob (#142/#144).
- **PR & Proposal Scrutiny Invariant (Validity, Utility & Source Issue Verification)**: Never assume changes proposed in pull requests (human- or bot-authored) or task plans are correct, relevant, or useful. Rigorously scrutinize whether the underlying premise is valid (does the claimed bug or problem actually exist in the code, or is it a hallucinated/misdiagnosed non-issue?), whether the proposed change is relevant to the repository's goals and scope, and whether it delivers genuine utility rather than code churn, redundant abstractions, or unnecessary refactoring. If the pull request originates from or links to a ticket/issue (GitHub Issue, Jira ticket, etc.), **you must review the source issue to ensure that the pull request actually and completely fulfills the requirements and acceptance criteria**. Reject or request changes for any PR that fails requirements, lacks genuine utility, or acts on an invalid premise.
- **Provider-wrapper review invariant**: For authorization or filtering wrappers, resolve the exact underlying result and canonical key/path before access decisions; apply projection before value resolution, preserve provider-specific parsing, and honor optional-interface contracts by interface presence.
- **Sandbox Bypass for Skill Scripts & `gh` CLI**: The default sandbox blocks `gh` CLI commands and any command referencing paths under `~/.gemini/config/skills/` due to glob-based path restrictions. Always run `gh` commands, `python3 <skill-dir>/scripts/...` invocations, and any command accessing skill paths with `BypassSandbox: true` — no need to attempt them sandboxed first. The glob error (`readonly ~/.gemini/config/skills/**: globs not supported`) was also observed on plain `grep`/`python3` against scratch paths (verified 2026-10-03), so retry such commands with `BypassSandbox: true` immediately.
- **`gh` output handling & Scratch Path Invariant**: `gh pr diff` stdout is truncated by the tool (only the tail survives). Never create a `scratch/` directory in the repository working tree; always store temporary files, diffs, and review payloads in the conversation artifact directory (`<appDataDir>/brain/<conversation-id>/scratch/` or `/tmp/`). Save diffs with `gh api repos/<o>/<r>/pulls/<n> -H "Accept: application/vnd.github.v3.diff" > /tmp/pr<n>.diff` and file contents with `-H "Accept: application/vnd.github.raw" > /tmp/file`, or run `github-cli/scripts/pr_audit_bundle.sh`. `gh api` has no `--output` flag, and `--jq` breaks on non-JSON responses.
- **Repo Routing**: When the user names a PR number, **always confirm which repo it belongs to** before attempting `gh pr view`. Do NOT default to `warpcode/dotfiles` — the user works across multiple repos (e.g. `warpcode/cloakenv`, `warpcode/dotfiles`). Use `gh pr view <n> --repo <owner>/<repo>` with the repo the user implies or ask to clarify if ambiguous.
- **AI Infrastructure**: Use **Docker Model Runner** (running `llama.cpp`) for local models over `ollama`.
- **Secrets Management**: Scripts and tools MUST remain blind to the secret provider (such as `cloakenv`); rely on standard environment variables (`GITHUB_TOKEN` / `GH_TOKEN`) or native tool configs. Secret resolution is handled via `bin/df.config` (`resolve`/`hydrate`) and `bin/df.keychain`/`bin/df.keepass`.
- **Package Management Architecture**: The legacy `zinstall` logic is deprecated; use the `pkg.zsh` recipe system (`pkg.recipe.define` + `registry.zsh`).
- **Profile Configuration Hierarchy**: Base configuration is loaded first, layered with `fs.profile.load` (`df.fs profile list`) overrides via `jq` recursive merge.
- **Service Logging**: macOS `launchd` agents use shell redirection (`>`) in `ProgramArguments` for log truncation on each run; Linux `systemd` services delegate to `journald` via `StandardOutput=journal`.
- **Conversation Reviews**: Conversation reviews must be compact and lean, containing strictly actionable suggestions, advice, and improvements (concrete diffs). Omit metadata headers, event stats, and compliance audit sections. Emphasize evaluating workflow scriptability: common procedures and recurring command chains should be scripted end-to-end to eliminate tool call sprawl and drastically cut context token usage.
