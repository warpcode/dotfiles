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
   - **Always ask for explicit user approval before destructive actions, approvals, or merging changes.** Detailed GitHub and PR review workflows are delegated to the `github` and `github-cli` skills.
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
- **Git & PR Workflows**: Delegated entirely to `git-expert`, `github`, and `github-cli` skills. Always use a rebase strategy when pulling or syncing remote changes.
- **Skill Blueprint Design**: Resources should **not** be marked as required in simple skill blueprints.
- **Skill Naming Convention**: Custom skills should be named directly following the format `{primary-thing}-{domain-area}` (e.g., `github-cli`, `shell-styling`, `jira-actions`). Do not append `-guidelines` or prefix everything with `prompt-` or `github-` unless it is directly applicable to that prefix/suffix.
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

## 🧠 Technical Memory (Durable Facts)

   ### `technical_context`
   - **Bootstrap Package Prerequisites**: `jq` is now a bootstrap package alongside `git`, `zsh`, and `curl` in `install.sh` to ensure early parsing capabilities for JSON declarative configuration files (such as scheduled tasks).
   - **Profile Configuration Loading Helper**: The general-purpose Zsh function `fs.profile.load` loaded in `src/zsh/functions/profile_loader.zsh` retrieves profile-specific configuration overrides in priority order (using `df.fs profile list`) and merges them recursively using `jq -s 'reduce .[] as $item ({}; . * $item)'`.
   - **Obsidian Migration**: The project has migrated Obsidian management from Zsh-based logic and Markdown rules to a standalone `bin/df.obsidian` utility with JSON validation rules. `src/zsh/apps/obsidian.zsh` now serves as a thin wrapper for this utility. Legacy Zsh functions and Markdown rule paths should be avoided.
   - **Obsidian Profile-Based Configuration Overrides**: Configuration overrides for Obsidian rules in `df.obsidian` must support the project's profile-based inheritance hierarchy (e.g., `work/default.json` and `work/${note_type}.json`). Use `df.fs profile list` to discover all profile-specific config files, and merge them in priority order using `jq -s 'reduce .[] as $item ({}; . * $item)'`.
   - **Scheduled Task Framework**: A user-space scheduled task framework (`scheduler.add`, `scheduler.logs`, etc.) is implemented using Gomplate templates to define declarative JSON tasks under `assets/configs/scheduler/`.
   - **Progressive Profile Overrides**: When building configuration merges across dotfiles profiles, prepend the baseline configuration first in the resolution chain (base -> global -> active profile) so that profile overrides layer correctly using recursive merge engines like jq.
   - **Secrets Architecture (Decoupled)**: The unified secret resolver has been completely migrated into `bin/df.config` under `resolve` and `hydrate`. The redundant `bin/df.secrets` wrapper has been removed. `bin/df.secrets.keychain` has been renamed to `bin/df.keychain` and is called directly by `df.config`, `df.keepass`, and `bin/sudo-askpass`.
   - **Config Hydration (Restored)**: `df.config hydrate` has its secrets resolution logic fully restored, querying `_resolve_secret_alias` internally to replace `{secret:...}` tokens using the unified profiles-based secrets registry and direct `df.keychain`/`df.keepass` providers.
   - **AI Backend Flexibility**: AI providers should not be hardcoded to specific backends (e.g., KeePassXC). Maintain modularity to allow switching or supporting multiple secret providers.
   - **Unique Temporary Files**: When creating temporary or staging files (e.g. for PR review payloads or command inputs), always generate unique filenames/paths and place them in a writeable directory (such as the conversation's scratch directory or local workspace) to prevent conflict and permission failures.
   - **Merge Regression Auditing**: Merges and rebases done by automated tools can inadvertently introduce minor regressions like stripping trailing newlines in configuration files (e.g., `Makefile`) or leading whitespace in test fixtures (e.g., `template_test.go`), which weakens parser testing. Always perform a direct file comparison (`diff`) between the target PR branch files and `main` to identify and revert these regressions.
   - **Script Execution Efficiency**: Do NOT open or read the full contents of utility, helper, or command scripts before executing them if their usage, parameters, and location are already documented. Directly execute them using the documented usage. Only read a script's source code if it is the target of a code review, modification, or debug task.
   - **Cloakpkg Go Version**: The `cloakpkg` project uses Go 1.23 on the `main` branch.
   - **CloakEnv CLI Architecture**: `@warpcode/cloakenv` is a URI-based dynamic runtime secret orchestrator (`keyring://`, `keepass://`, `yaml://`, `json://`, `env://`, `cache://`, `search://`). It has no `export` subcommand or `--path`/`--namespace`/`CLOAK_TOKEN` flags. Programmatic retrieval is performed via `cloakenv get <uri>` (raw stdout) and `cloakenv show <entry-uri> -o json` (structured entries).
   - **Hermes SecretSource Plugin Requirements**: Custom Hermes `SecretSource` plugins subclass `agent.secret_sources.base.SecretSource` and return a `FetchResult`. Subprocess CLI calls via `run_secret_cli` must pass system D-Bus and XDG environment variables (`DBUS_SESSION_BUS_ADDRESS`, `XDG_RUNTIME_DIR`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `USER`) to preserve Linux Keyring/Secret Service connectivity.

   ### `decision`
   - **Prevent Infinite Log Growth in Scheduled Services**: macOS launchd services MUST use shell redirection (`>`) in the `ProgramArguments` block to truncate logs on every run; Linux systemd services MUST delegate logging to `journald` via `StandardOutput=journal` instead of writing to static files.
   - **Subagent Model Routing**: Whenever a subagent is spawned to handle code grepping or file reading, do NOT use the master model. Set `inherit = false` for the subagent context and explicitly enforce the target model as `gemini-3.5-flash`.

   ### `correction`
   - **Obsidian Slugification**: Resolved. The regression in PR #40 where slugification was too aggressive was fixed by restoring the legacy ${note_title// /-} logic in `bin/df.obsidian`.
