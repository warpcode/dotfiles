# Global Agent Instructions

Persistent behavioral guardrails and universal preferences across repositories.

## Behavioral Guardrails

1. **Instruction Fidelity & Scope**:
   - **Do not proactively refactor** or introduce unrequested abstractions when only a proposal, suggestion, or targeted fix is requested.
   - **Do not hallucinate helper functions**: Never assume unimported/undefined functions exist or invent unprompted helpers.

2. **Code & Logic Preservation**:
   - Never remove existing error messages, logging, comments, or essential logic during refactoring.

3. **Pre-Action Safety Gate & State Verification**:
   - **Always request explicit user approval** before destructive actions (`rm`, `reset`, `git push --force`, network-impacting changes, or merging PRs).
   - **Symlink Safety**: NEVER perform bulk deletion (`rm -rf`) on directories without first checking if the target is a symlink (`readlink` or `ls -l`). Delete the symlink itself, not the target contents.
   - Verify state before mutating and verify file edits are persisted to disk. Temporary session scratch files can be cleaned up without prompting.
   - **Verb Substitution Ban**: When a user requests a reversible or descriptive operation (archive, hide, close, tidy, move, stash, revert) and the available tooling offers a destructive equivalent (delete, drop, destroy, purge, reset), you MUST NOT substitute. Stop and ask.
   - **Capability Check Before Destructive Substitution**: Before using a destructive operation to satisfy a request, first verify (read-only) whether a non-destructive equivalent exists. If the only way to check is itself a mutating call, abort and ask.
   - **Irreversibility Asymmetry**: Irreversible operations REQUIRE (a) the user explicitly naming the irreversible action ("delete", "permanently remove", "destroy"), and (b) an immediate pre-flight confirmation.
   - **Batch Safety**: Never batch irreversible operations in a shell loop. Dry-run first, verify the target set, then execute one at a time.

4. **UI Stability & Decision Presentation**:
   - **Never call `update_topic` and `ask_user` in the same turn.** Set topic first, then call `ask_user` in the subsequent turn to avoid raw JSON rendering in CLI.
   - **Recommendation Invariant**: Whenever presenting choices, options, or next steps, ALWAYS explicitly state the recommended choice along with the underlying rationale.
   - **Interactive Suggestion Options**: When presenting suggestions, proposals, or concrete plans, provide interactive selectable options via `ask_question` to approve, suggest changes, or reject, listing the recommended choice first.
   - **Artifact Gating vs Modal Questions**: When creating an artifact with `RequestFeedback: true`, do NOT chain an immediate `ask_question` modal in the same turn. Allow the user to inspect the artifact first.

5. **Resource Selection & Delegation**:
   - Check whether an existing skill applies before executing and follow its guidelines.
   - Delegate simple/mechanical tasks and high-noise exploration (broad searches, large logs, multi-file sweeps, routine validations, and bulk extractions) to subagents using light models (`flash` / `gemini-3.5-flash` with uninherited context). Keep judgement, design, and final verification in the parent; give light subagents a precise brief and explicit output format, and spot-check results.
   - **Thinking Effort Calibration**: Match reasoning effort to task complexity (`none`/`low` for simple lookups/mechanical tasks; `medium`/`high` for architectural reasoning, subtle debugging, or complex trade-offs).
   - **Script Execution Efficiency**: Do NOT open/read utility or helper script source code if usage and parameters are documented in `SKILL.md`. Run them directly.
   - **Skill Script Path Resolution**: Resolve bundled skill scripts relative to the active skill package directory (`.github/skills/<skill-name>/scripts/<name>` or `~/.gemini/config/skills/<skill-name>/scripts/<name>`), never as `./scripts/<name>` from the workspace root.

6. **Tool Parameter & Command Hygiene**:
   - Never pass unnecessary escaped literal quotes in tool arguments (e.g., use `"/path"`, not `"\"/path\""`).
   - **No Inline Python Scripts**: NEVER execute `python3 -c "..."` or heredoc Python scripts in `run_command`. Rely on skill subcommands or dedicated scripts.
   - **No Shell Sleep**: Never run background or chained `sleep` commands in shell strings (`sleep <n> && ...`). Rely on reactive event notifications, background task completion, or the timer tool.
   - **No Duplicate File Reads**: Do not re-read files that are already present in context unless a write, edit, or build command has altered them on disk.
   - **No N+1 PR Inspection Loops**: Never loop `gh pr view <n>` across multiple PRs in shell loops (`for pr in ...; do gh pr view ...`). Use `pr_state_rollup.py` or bulk repository fetches (`gh pr list`).
   - **Non-Interactive Git Execution**: Never run `git rebase` or interactive commands without `-c core.editor=true` or `GIT_EDITOR=true` to prevent interactive terminal hangs.
   - **Subagent Reactive Wakeups**: Never poll `manage_subagents` in loops; allow background task notifications and reactive wakeups to resume execution.
   - **Background Task Completion**: When a command is sent to the background via `run_command`, do NOT schedule redundant one-shot timers on its task ID or poll `manage_task status`. The system automatically notifies you with a high-priority message upon task completion; simply stop calling tools to await completion.
   - **PR Branch Synchronization Invariant**: NEVER force-push or rebase PR branches to resolve merge conflicts. Update PR branches by merging `origin/master` (`git merge origin/master`), running regression tests in an isolated worktree, and pushing via standard push. Squash-merging on GitHub produces a single clean commit.

7. **Conflict Resolution Order**: Safety > User Intent > Simplicity > Local Convention.

## Global Technical Invariants

- **Source of Truth Hierarchy**: `~/.agents/AGENTS.md` is the authoritative source for global durable memory; keep workspace-only notes in repo `AGENTS.md` or ephemeral.
- **Proposal Scrutiny**: Never assume proposed plans or PR changes are valid or useful without verifying the underlying premise, scope relevance, and source issue requirements.
- **Sandbox Bypass**: In sandboxed CLI harnesses supporting `BypassSandbox: true`, run `gh` commands, skill script invocations (`~/.gemini/config/skills/`), and isolated worktree operations (`/tmp/wt-*`) with `BypassSandbox: true` from the first attempt.
- **AI Infrastructure**: Use **Docker Model Runner** (running `llama.cpp`) for local models over `ollama`.
