# Agent Instructions for warpcode/dotfiles

These instructions capture persistent memories, behavioral guardrails, and technical preferences for this workspace.

## 🧠 Behavioral Guardrails

1. **Strict Instruction Following**: 
   - **Do not proactively refactor** code when only a suggestion or proposal is requested (e.g., "No, don't refact, I want suggestion").
   - **Do not hallucinate helper functions**: Do not assume the existence of functions that haven't been defined, and do not add unrequested helper functions.

2. **Code Preservation**:
   - Never remove existing error messages, logging, or essential logic during refactoring.

3. **State Verification**:
   - Always verify the current state before taking proactive actions like creating snapshots.
   - Verify that file updates were actually saved to disk after making edits.
   - **Symlink Safety**: NEVER perform bulk deletion operations (`rm -rf`) on directories without first verifying if the target is a symlink (`readlink` or `ls -l`). If replacing a symlinked folder, remove the symlink itself, not its contents.

4. **UI Stability**:
   - **Never call `update_topic` and `ask_user` in the same turn.** Sequencing these tools in a single turn causes the CLI to display raw JSON instead of the interactive menu. Always call `update_topic` to set context, then issue `ask_user` in a separate, subsequent turn.

5. **Approval Workflow**:
   - **Always ask for explicit user approval before approving or merging a pull request**, regardless of whether verification was successful.
   - **Approval for Batching**: ALWAYS obtain explicit user permission before processing multiple pull requests in a single review session.
   - **Review Boundaries**: When discovering multiple PRs, strictly limit auditing and commentary to the specific PR(s) selected by the user. Do not proactively audit other candidates in the same turn or session unless explicitly requested.
   - **Review Orchestration**: Formal pull request reviews SHOULD be performed using the `review-pull-request` agent. This ensures a consistent lifecycle including discovery, specialized subagent audits (e.g., `file-cleaner`), and automatic memory extraction via `conversation-review`.
   - **Code Review Phase Separation**: During active PR review workflows (e.g. `/review-pull-request`), treat any user architectural ideas, cleanup requests, or file removal proposals as requested review comments to be submitted to GitHub. Do NOT checkout the branch or perform local workspace edits unless the user explicitly commands a local change or workspace modification.
   - **Strict Thread Resolution**: Only resolve a review thread if the corresponding change is verified as fully and correctly implemented. If a finding is not fully resolved, do not resolve the thread; post a reply comment on the existing thread explaining what is still outstanding.
   - **Rebase Conflict Handling**: When requested to resolve merge conflicts on a PR branch, perform a proper git rebase of the target base branch onto the PR branch, resolve conflicts cleanly (e.g., using a worktree), and force-push the updated branch back to the remote.
6. **Precedence & Integrity**:
  - Skill instructions and engineering standards take precedence over context-efficiency heuristics.
  - Do not skip mandated procedural steps (for example, explicit validation or required intermediate artifacts) only to reduce turns or tokens.
  - Prefer technically stable workflows over fragile one-liners when correctness is at risk.

7. **Resource Selection**:
  - Before acting, check whether an existing skill applies and load it before execution.
  - Choose the best execution surface per task (skill, MCP/tool, subagent, or inline execution) and drop stale approaches when context changes.

8. **Delegation Heuristic**:
  - Use subagents for high-noise exploration (broad searches, large logs, multi-file research) to keep coordinator context focused.
  - Provide self-contained directives to subagents and consume only synthesised results.

9. **Pre-Action Safety Gate**:
  - Before destructive operations (`rm`, `reset`, `chmod`, or network-impacting operations), request explicit user confirmation. Temporary or staging files created during the session inside the conversation's scratch directory (e.g., review payloads) can be cleaned up or deleted without prompting.
  - For non-trivial edits, explicitly validate affected paths and intent prior to mutation.

10. **Conflict Resolution Order**:
  - Resolve directive conflicts in this order: safety, user intent, simplicity, then local convention.

11. **Ticket Context Completeness**:
   - Any generated task/issue/ticket must be context-complete and executable without chat history.
   - Include required skills/guidelines, decision logic, expected output schema, and explicit file paths/dependency chains.

12. **Tool Parameter Hygiene**:
   - When invoking tools or defining subagents, configs, or resources, ensure string arguments do not contain unnecessary escaped literal quotes (e.g. use "/path/to/dir", not "\"/path/to/dir\""). This applies to all parameters across all tools, including list_dir, view_file, and find_by_name, to prevent execution and parsing failures.

13. **Script Execution Efficiency (Token Preservation)**:
   - Do NOT open or read the full contents of utility, helper, or command scripts before executing them if their usage, parameters, and location are already documented in `SKILL.md` or other instructions.
   - Directly execute them using the documented usage. Only read a script's source code if it is the target of a code review, modification, or debug task.

## 🛠️ Technical Context & Preferences

- **Source of Truth Hierarchy**: `~/.agents/AGENTS.md` is the authoritative source for durable, graduated rules and conventions. Project-local guidance should align to this core memory file, and mature patterns should be promoted into dedicated skills when appropriate.
- **Memory Tiers**: Durable memory should be centralized in `~/.agents/AGENTS.md`. Keep workspace-only notes ephemeral and avoid maintaining parallel persistent memory files in this repository.
- **Git Workflow**:
  - Always use a rebase strategy when pulling or syncing remote changes (e.g., `git pull --rebase` or configure the repository using `git config pull.rebase true`).
  - All GitHub Actions MUST pass before any merge.
  - Prefer squash-and-merge for pull requests.
  - Remote branches MUST be deleted immediately after merging.
  - Before approving or merging any pull request, the AI agent MUST run `~/.agents/skills/github-review-orchestrator/scripts/pre_merge_checks.sh <pr_number>` to automate verification checks.
- **Code Review Style**: Delegated entirely to `github` and `technical-review-guidelines` skills. Do not duplicate rules here.
- **Skill Blueprint Design**: Resources should **not** be marked as required in simple skill blueprints.
- **Skill Naming Convention**: Custom skills should be named directly following the format `{primary-thing}-{domain-area}` (e.g., `github`, `shell-styling`, `jira-actions`). Do not append `-guidelines` or prefix everything with `prompt-` or `github-` unless it is directly applicable to that prefix/suffix.
- **Skill Lifecycle & Granularity**: When creating or reviewing skills, explicitly evaluate whether to:
  - **Merge**: Collate smaller, overlapping, or fragmented skills into a unified capability.
  - **Break Up**: Deconstruct large, multi-purpose skills into smaller, single-responsibility skills.
- **AI Tooling / Infrastructure**:
  - Use **Docker Model Runner** (which runs `llama.cpp`) for running local models directly, rather than defaulting to `ollama`.
  - Deepseek API pricing is $0.48 per million tokens.
- **Script & Tool Efficiency**:
  - All scripts interacting with APIs (GitHub, etc.) MUST implement batching by default when dealing with multiple entities.
  - Avoid iterative per-item network calls in shell loops or high-level orchestration logic.
  - **Skill Script Path Resolution**: If a skill references a script using a relative path, agents MUST resolve and check that path from the skill's own directory first before attempting repository-root or other fallback paths.
  - **Stdout Preference**: Prefer scripts that output data directly to `stdout` rather than requiring a temporary file path, especially for data intended for immediate consumption.
  - When using `gh api graphql`, pass queries via variable injection to avoid shell quoting and path resolution issues.
  - **GH CLI Escaping Safety**: When updating, replying, or posting review comments via `gh api` containing backticks, brackets, or code tokens, write the payload to a JSON file and load it using `--input <file>` rather than inline shell flags (e.g. `--field` or `-f`) to prevent shell substitution and character stripping.
- **Package Management Architecture**: The legacy `zinstall` logic is deprecated. The project is migrating towards a unified `pkg.zsh` architecture using a `recipe` dictionary format that explicitly defines methods for checking, updating, installing, and enabling packages.
- **Skill Development Standards**:
  - **Token Efficiency**: Scripts intended for AI consumption MUST prioritize token-efficient summaries (e.g., Markdown) by default to minimize context usage.
  - **Raw Output**: All scripts MUST implement a `--raw` (or `--raw-output`) flag. This flag is reserved for debugging, manual inspection, or piping to other tools; it MUST NOT be used by AI agents during standard orchestration phases.
  - **Template Externalization**: Fixed output structures (like Markdown reports) MUST be externalized into a `templates/` directory within the skill folder.
- **Tool Compatibility**:
  - **yq**: The environment uses `mikefarah/yq` (v4). Avoid `jq`-specific functions like `any()` or `from_json` unless verified. Pass search values via individual environment variables or delimited strings with `split()`.
- **Zsh Nuances**:
  - **Dynamic Substitution**: Zsh's `${var//pat/repl}` with `(#b)` allows dynamic expansion of backreferences within `${(P)...}` for each match. This is the preferred way to safely expand environment variables in lazy-loaded commands.
  - **Robust Array Hydration from Stdout**: When capturing command output representing lists or files (e.g., from `df.fs profile list`), always use Zsh's native line-splitting flag `( ${(f)"$(...)"} )` to populate arrays. This prevents accidental word-splitting on spaces and ensures correct behavior.
- **Architectural Decisions**:
  - **Log Rotation (macOS)**: Preferred log rotation for `launchd` agents is via shell redirection (`>`) in the `ProgramArguments` block to ensure truncation on every run, rather than using `StandardOutPath`.
  - **Service Logging (Linux)**: `systemd` services should delegate log management to `journald` via `StandardOutput=journal` instead of writing to static files.
  - **Secrets Blindness**: Custom scripts and skills interacting with remote APIs (e.g. GitHub) MUST remain completely blind to the secret provider (such as `cloakenv`). The scripts should only rely on standard environment variables (like `GITHUB_TOKEN` / `GH_TOKEN`) or native tool configurations. The wrapping of commands with `cloakenv` is strictly the responsibility of the high-level agent orchestration.
  - **CLI & API Fallbacks**: Scripts interfacing with GitHub should check if the `gh` CLI is installed and authenticated. If authenticated, they should use the CLI. If not authenticated, guide the user to `gh auth login` or enable the GitHub MCP server. Do NOT fall back to raw `curl` API calls.
  - **Branch Dynamism**: Pull request review and validation scripts MUST NOT hardcode default branch names (such as `origin/master` or `master`). Instead, query the pull request metadata dynamically to determine the target base branch.
  - **Git vs. GitHub Domain Separation**: Keep Git-specific commands and logic (e.g. local branching, commits, diffs) logically separate from GitHub API integrations (e.g. issues, pull requests, reviews). Git operations should reside in general git skills/scripts, not inside github-prefixed ones.

- **PR Review Hygiene**: Delegated entirely to `github` skill.

## 🤖 Autonomous VM Agents (Jules)

When operating as an autonomous agent in a remote virtual machine (e.g., Jules):

1. **Active Memory and Context Retrieval**:
  - Before drafting any implementation plan or modifying code, you MUST read `~/.agents/AGENTS.md` to load active user preferences, past corrections, and decision records.
   - If the task involves modifying Zsh configuration or Zsh scripts, you MUST read and follow `./.github/instructions/zsh.instructions.md`.

2. **Leverage Local Skills & Workflows**:
    - Do not write redundant scripts or reinvent existing logic. Review the custom skills in `./.github/skills/` (such as `github`, `technical-review-guidelines`, and `git-expert`) and agent workflows in `./.github/agents/` to leverage existing automation patterns and CLI utilities.

3. **Conventions & Safe Operations**:
   - Adhere strictly to the package management guidelines. Do not install packages using raw `apt` or `brew` commands. Use the modular `pkg.zsh` recipe structure.
   - Do not edit stowed files in the home directory directly. Make modifications in the source files located under the `generic/` directory.

4. **Scope Hygiene & File Purging**:
   - Always perform a thorough audit of the pull request file list against `master` using `git diff --name-status master`.
   - Purge any accidentally restored legacy directories (such as obsolete Zsh package managers or old AI skill configurations), git submodules, or temporary analysis files (like `coding/tmp/`).
   - Revert all unrelated scope creep modifications (such as git, ssh, or secret configuration moves) to match `master` exactly. Feature branches must strictly contain only files relevant to the target issue.

5. **Plan Affirmation**:

   ## 🧠 Technical Memory (Durable Facts)

   ### `technical_context`
   - **Bootstrap Package Prerequisites**: `jq` is now a bootstrap package alongside `git`, `zsh`, and `curl` in `install.sh` to ensure early parsing capabilities for JSON declarative configuration files (such as scheduled tasks).
   - **Profile Configuration Loading Helper**: The general-purpose Zsh function `fs.profile.load` loaded in `src/zsh/functions/profile_loader.zsh` retrieves profile-specific configuration overrides in priority order (using `df.fs profile list`) and merges them recursively using `jq -s 'reduce .[] as $item ({}; . * $item)'`.
   - **Obsidian Migration**: The project has migrated Obsidian management from Zsh-based logic and Markdown rules to a standalone `bin/df.obsidian` utility with JSON validation rules. `src/zsh/apps/obsidian.zsh` now serves as a thin wrapper for this utility. Legacy Zsh functions and Markdown rule paths should be avoided.
   - **Obsidian Profile-Based Configuration Overrides**: Configuration overrides for Obsidian rules in `df.obsidian` must support the project's profile-based inheritance hierarchy (e.g., `work/default.json` and `work/${note_type}.json`). Use `df.fs profile list` to discover all profile-specific config files, and merge them in priority order using `jq -s 'reduce .[] as $item ({}; . * $item)'`.
   - **Redundant tostring in yq**: In `mikefarah/yq` (v4), variables retrieved via `strenv()` are already strings; applying `| tostring` to them is redundant. If type conversion is required, it should be applied to the field being compared rather than the strenv variable.
   - **Scheduled Task Framework**: A user-space scheduled task framework (`scheduler.add`, `scheduler.logs`, etc.) is implemented using Gomplate templates to define declarative JSON tasks under `assets/configs/scheduler/`.
   - **Progressive Profile Overrides**: When building configuration merges across dotfiles profiles, prepend the baseline configuration first in the resolution chain (base -> global -> active profile) so that profile overrides layer correctly using recursive merge engines like jq.
   - **Secrets Architecture (Decoupled)**: The unified secret resolver has been completely migrated into `bin/df.config` under `resolve` and `hydrate`. The redundant `bin/df.secrets` wrapper has been removed. `bin/df.secrets.keychain` has been renamed to `bin/df.keychain` and is called directly by `df.config`, `df.keepass`, and `bin/sudo-askpass`.
   - **Config Hydration (Restored)**: `df.config hydrate` has its secrets resolution logic fully restored, querying `_resolve_secret_alias` internally to replace `{secret:...}` tokens using the unified profiles-based secrets registry and direct `df.keychain`/`df.keepass` providers.
   - **AI Backend Flexibility**: AI providers should not be hardcoded to specific backends (e.g., KeePassXC). Maintain modularity to allow switching or supporting multiple secret providers.
   - **KeePassXC CLI Attachment Operations**: `keepassxc-cli` does not feature an `attachment-list` subcommand. To list attachments, run `keepassxc-cli show --show-attachments <db> <entry>` and parse the output block. To stream attachments to stdout, use `keepassxc-cli attachment-export <db> <entry> <name> --stdout`.
   - **KeePassXC Decryption Performance**: Running `keepassxc-cli show` sequentially inside shell loops (even when parallelized via `zargs` across entries) introduces significant latency because every process invocation decrypts the database. Always fetch all attributes of an entry in a single process invocation and parse the results in-memory.
   - **Symlink Replacement in Install Scripts**: When replacing a symlinked directory, always recreate the directory (`mkdir -p`) immediately after deleting the symlink using `rm -f` to ensure subsequent copying operations (such as `cp -a`) do not fail.
   - **Keyring/Cache Testing Isolation**: In secret orchestrator tests (e.g. `cloakenv`), tests that interact with cache/keyring providers must call `keyring.MockInit()` and isolate `HOME`, `XDG_CACHE_HOME`, and `LocalAppData` to a temporary directory (`t.TempDir()`) to avoid local data loss.
   - **Go Pipe-Based Redirection Safety in Tests**: In Go tests that redirect stdout/stderr using `os.Pipe()`, check the returned error immediately. Defer closing both writer ends (`wOut.Close()`, `wErr.Close()`) immediately after creation to prevent resource leaks (file descriptors and background goroutines waiting for EOF) if the test function panics.
   - **Unique Temporary Files**: When creating temporary or staging files (e.g. for PR review payloads or command inputs), always generate unique filenames/paths and place them in a writeable directory (such as the conversation's scratch directory or local workspace) to prevent conflict and permission failures.
   - **Merge Regression Auditing**: Merges and rebases done by automated tools can inadvertently introduce minor regressions like stripping trailing newlines in configuration files (e.g., `Makefile`) or leading whitespace in test fixtures (e.g., `template_test.go`), which weakens parser testing. Always perform a direct file comparison (`diff`) between the target PR branch files and `main` to identify and revert these regressions.
   - **Script Execution Efficiency**: Do NOT open or read the full contents of utility, helper, or command scripts before executing them if their usage, parameters, and location are already documented. Directly execute them using the documented usage. Only read a script's source code if it is the target of a code review, modification, or debug task.
   - **Cloakpkg Go Version**: The `cloakpkg` project uses Go 1.23 on the `main` branch.
   - **gh API File GraphQL Parameters**: When calling `gh api graphql` with a query stored in a file, always pass the query using the uppercase `-F` parameter (e.g., `-F query=@/path/to/query.gql`) rather than the lowercase `-f`, which interprets the argument as a literal query string.
   - **Cloakpkg Integration Test Package Assertion**: In `cloakpkg` integration tests, when verifying package commands for installers using the `--` argument separator (like `apt-get`, `dnf`, and `snap`), package names begin at argument index 4 (`cmd[4:]`), whereas for installers not using `--` (like `pacman`), they begin at index 3 (`cmd[3:]`).
   - **Snap Installer Parameter Injection Protection**: The `snap` package installer in `cloakpkg` uses the `--` argument separator before the packages list for `install`, `remove`, and `refresh` actions to prevent parameter injection.
   - **zsh -n Gotcha**: `zsh -n` only syntax-checks the first file argument when multiple arguments are provided. When linting multiple Zsh files, run `zsh -n` on each file individually (e.g., via `find ... -exec zsh -n {} \;` or a loop).
   - **Piping Exit Status Masking**: Piping command outputs directly to other commands (like `grep`) masks the preceding command's exit code. For critical CI validations, check the elements of the `pipestatus` array (in Zsh) or `PIPESTATUS` (in Bash) or avoid inline pipelines if exit code propagation is required.
   - **Go Test Code Quality Auditing**: Test code quality is audited against Google's Go Style Guide, verifying table-driven subtests, standard library assertions (no external assert packages), descriptive diagnostics, and deferred mock restorations to prevent test pollution.
   - **Go Test Temporary Directory Usage**: Standard Go unit tests MUST prefer `t.TempDir()` over manual `os.MkdirTemp` and `defer os.RemoveAll` to ensure automatic test isolation and reliable directory cleanup upon test completion.
   - **Table-Driven Test Assertion Hygiene**: Table-driven test loops in Go MUST NOT contain hardcoded conditional branches matching specific test case names (e.g., `if tt.name == "..."`). All expected outcomes, error substrings, or variations must be encoded directly into the test table fields (e.g., `wantErr`).
   - **Jules Partial-Fix Pattern — Redundant Cleanup Calls**: When Jules addresses a `t.TempDir()` review finding, it may switch `os.MkdirTemp` to `t.TempDir()` but fail to remove the accompanying `defer os.RemoveAll(tempDir)` call. This produces a redundant and misleading cleanup call since `t.TempDir()` already registers cleanup via `t.Cleanup()`. Always inspect subsequent Jules commits for this specific residual artifact when the original finding involved temporary directory handling.
   - **Broken Skill Symlinks Under `~/.gemini/config/skills/`**: Skill `SKILL.md` files and scripts under `/home/jase/.gemini/config/skills/` are symlinks pointing to `/home/jase/src/dotfiles/dot_agents/skills/`. The `view_file` tool returns "no such file" errors for these symlinks. To read them, use a shell workaround: `python3 -c "print(open('/path/to/SKILL.md').read())"` (requires `BypassSandbox: true`). Similarly, skill scripts listed by `ls` may not be directly executable. Verify with `ls -la` before attempting to run them.
    - **`submit_review.sh` is a Broken Symlink**: The `submit_review.sh` script at `/home/jase/.gemini/config/skills/github-review-orchestrator/scripts/submit_review.sh` is a broken symlink to `/home/jase/src/dotfiles/dot_agents/skills/github-review-orchestrator/scripts/submit_review.sh`. Do NOT attempt to use it. Submit PR reviews directly via: `gh api "repos/{owner}/{repo}/pulls/{pr}/reviews" --method POST --input <payload-file>`.
    - **Jules Root File Pollution (`memory.md`)**: Autonomous bot agents (e.g., Jules) may generate root `memory.md` summary notes during refactoring tasks. PR reviews must reject root memory files and request their deletion via inline file comments to prevent persistent repository clutter.


   ### `decision`
   - **Prevent Infinite Log Growth in Scheduled Services**: macOS launchd services MUST use shell redirection (`>`) in the `ProgramArguments` block to truncate logs on every run; Linux systemd services MUST delegate logging to `journald` via `StandardOutput=journal` instead of writing to static files.
   - **Interactive Zsh Functions Safety**: Interactive Zsh functions (like `dataurl`) must always use `return <status>` instead of `exit` to prevent terminating the active shell session, and must verify file readability using `[ -f "$file" ]` beforehand.
   - **Argument-Based JSON in Zsh**: When passing resolved JSON objects between shell functions or into jq, pass them as parsed arguments (e.g., jq --argjson defaults "$default_json") rather than using process substitutions (<(echo ...)) or raw slurping, preventing zsh compatibility issues and descriptor leaks.
   - **Subagent Model Routing**: Whenever a subagent is spawned to handle code grepping or file reading, do NOT use the master model. Set `inherit = false` for the subagent context and explicitly enforce the target model as `gemini-3.5-flash`.
   - **Git Merge Conflict Review Style**: In code reviews, if a branch has merge conflicts with the target branch, instruct the author to perform a proper git rebase/merge instead of file overwrites or manual copies.
   - **PR Review Event Mapping**: If a PR review contains any findings (including those of **Low** severity), submit the review as `REQUEST_CHANGES` rather than `COMMENT`.
   - **PR Review Conflict Commenting**: When requesting changes due to merge conflicts or general findings, always add corresponding inline comments directly to the affected files in the review payload to ensure external integrations and bots detect the changes required.
   - **Inline Comments Required for Bot-Authored PRs**: When reviewing PRs authored by automated bots (e.g., Jules), all findings MUST be submitted as inline file comments on the specific lines, not in the main review body. Bot authors respond to inline comments; findings in the review body alone are ignored. The main review body should be a neutral, brief summary only.
   - **Atomically Submit Mixed-Type Reviews via GraphQL**: To submit a pull request review containing both line-level comments and file-level comments (e.g., comments on binary files or without specific line numbers), do not use the REST API reviews endpoint (which rejects `subject_type: file` with HTTP 422). Instead, use the GraphQL mutations workflow: create a pending review via `addPullRequestReview`, attach comments via `addPullRequestReviewThread` (using `subjectType: FILE` for file-level comments), and finalize via `submitPullRequestReview`.

   ### `correction`
   - **Obsidian Slugification**: Resolved. The regression in PR #40 where slugification was too aggressive was fixed by restoring the legacy ${note_title// /-} logic in `bin/df.obsidian`.
   - **Neutrality in Code Reviews**: Do not include encouraging adjectives, subjective evaluations, or conversational filler (e.g., "looks excellent", "successfully", "elegantly") in PR review comments or body copy. Maintain a completely factual and technical tone.
