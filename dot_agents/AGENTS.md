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
  - Before destructive operations (`rm`, `reset`, `chmod`, or network-impacting operations), request explicit user confirmation.
  - For non-trivial edits, explicitly validate affected paths and intent prior to mutation.

10. **Conflict Resolution Order**:
  - Resolve directive conflicts in this order: safety, user intent, simplicity, then local convention.

11. **Ticket Context Completeness**:
  - Any generated task/issue/ticket must be context-complete and executable without chat history.
  - Include required skills/guidelines, decision logic, expected output schema, and explicit file paths/dependency chains.
## 🛠️ Technical Context & Preferences

- **Source of Truth Hierarchy**: `~/.agents/AGENTS.md` is the authoritative source for durable, graduated rules and conventions. Project-local guidance should align to this core memory file, and mature patterns should be promoted into dedicated skills when appropriate.
- **Memory Tiers**: Durable memory should be centralized in `~/.agents/AGENTS.md`. Keep workspace-only notes ephemeral and avoid maintaining parallel persistent memory files in this repository.
- **Git Workflow**:
  - Always use a rebase strategy when pulling or syncing remote changes (e.g., `git pull --rebase` or configure the repository using `git config pull.rebase true`).
  - All GitHub Actions MUST pass before any merge.
  - Prefer squash-and-merge for pull requests.
  - Remote branches MUST be deleted immediately after merging.
  - Before approving or merging any pull request, the AI agent MUST run `./.agents/skills/github-review-orchestrator/scripts/pre_merge_checks.sh <pr_number>` to automate verification checks.
- **Code Review Style**: Delegated entirely to `github-review-orchestrator` and `technical-review-guidelines` skills. Do not duplicate rules here.
- **Skill Blueprint Design**: Resources should **not** be marked as required in simple skill blueprints.
- **Skill Naming Convention**: All custom skills MUST be named using the format `prefix-{specific-area}-guidelines`.
  - For LLM instructions, agent orchestration, or prompt engineering: `prompt-*` MUST be the prefix (e.g., `prompt-guidelines`, `prompt-skills-guidelines`).
  - For memory management, extraction, and lifecycle operations: `memory-*` MUST be the prefix (e.g., `memory-analysis-guidelines`, `memory-operations-guidelines`). Note: Memory operations are distinct from prompt engineering.
  - For GitHub-related skills/integrations: `github-*` MUST be the prefix (e.g., `github-review-guidelines`).
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

- **PR Review Hygiene**: Delegated entirely to `github-review-orchestrator` skill.

## 🤖 Autonomous VM Agents (Jules)

When operating as an autonomous agent in a remote virtual machine (e.g., Jules):

1. **Active Memory and Context Retrieval**:
  - Before drafting any implementation plan or modifying code, you MUST read `~/.agents/AGENTS.md` to load active user preferences, past corrections, and decision records.
   - If the task involves modifying Zsh configuration or Zsh scripts, you MUST read and follow `./.github/instructions/zsh.instructions.md`.

2. **Leverage Local Skills & Workflows**:
    - Do not write redundant scripts or reinvent existing logic. Review the custom skills in `./.github/skills/` (such as `github-review-orchestrator`, `technical-review-guidelines`, and `github-pull-guidelines`) and agent workflows in `./.github/agents/` to leverage existing automation patterns and CLI utilities.

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

   ### `decision`
   - **Prevent Infinite Log Growth in Scheduled Services**: macOS launchd services MUST use shell redirection (`>`) in the `ProgramArguments` block to truncate logs on every run; Linux systemd services MUST delegate logging to `journald` via `StandardOutput=journal` instead of writing to static files.
   - **Interactive Zsh Functions Safety**: Interactive Zsh functions (like `dataurl`) must always use `return <status>` instead of `exit` to prevent terminating the active shell session, and must verify file readability using `[ -f "$file" ]` beforehand.
   - **Argument-Based JSON in Zsh**: When passing resolved JSON objects between shell functions or into jq, pass them as parsed arguments (e.g., jq --argjson defaults "$default_json") rather than using process substitutions (<(echo ...)) or raw slurping, preventing zsh compatibility issues and descriptor leaks.
   - **Subagent Model Routing**: Whenever a subagent is spawned to handle code grepping or file reading, do NOT use the master model. Set `inherit = false` for the subagent context and explicitly enforce the target model as `gemini-3.5-flash`.

   ### `correction`
   - **Obsidian Slugification**: Resolved. The regression in PR #40 where slugification was too aggressive was fixed by restoring the legacy ${note_title// /-} logic in `bin/df.obsidian`.
   - **Neutrality in Code Reviews**: Do not include encouraging adjectives, subjective evaluations, or conversational filler (e.g., "looks excellent", "successfully", "elegantly") in PR review comments or body copy. Maintain a completely factual and technical tone.
