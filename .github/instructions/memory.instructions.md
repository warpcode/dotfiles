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
## 🛠️ Technical Context & Preferences

- **Git Workflow**:
  - All GitHub Actions MUST pass before any merge.
  - Prefer squash-and-merge for pull requests.
  - Remote branches MUST be deleted immediately after merging.
- **Code Review Style**:
  - **Tone & Content**: Strictly neutral and formal. Avoid conversational filler, encouraging remarks, or summarizing work the user is already aware of. Never use "LGTM" or unnecessary affirmations. Do not repeat yourself. For each technical issue, the comment MUST state: **Severity** (High, Medium, or Low), **Description** of the issue, **Impact** (why it is a problem), and a **Proposed Solution** (including code examples where applicable).
  - **Commentary**: Do not provide summaries of work done if it was explicitly requested by the user or is already visible in the PR; provide only the technical review findings. Do not paraphrase the task or the developer's work.
  - **Approval**: If approving a pull request, NEVER add NEW comments to files. Do not provide a summary if there is nothing new to add; just ask to approve.
  - **Replies**: Only reply if needed (with user approval). Give a thumbs up (👍) ONLY if the developer replied saying they fixed a requested change.
  - **Resolution**: Proactively resolve review threads once the corresponding changes have been verified in the diff. If the developer asks a question, alert the user for a response.
  - **Format**: Use line-level comments for specific issues and file-level comments for file-wide concerns. If nothing is wrong, do not add any comments. Comments MUST NOT use 'caveman' style. Use plain English to describe the issue, explain why it is a problem, and suggest a potential solution using the mandatory structure defined in Tone & Content.
- **Skill Blueprint Design**: Resources should **not** be marked as required in simple skill blueprints.
- **Skill Naming Convention**: All custom skills MUST be named using the format `prefix-{specific-area}-guidelines`.
  - For skills, agents, or agentic instructions (using markdown, etc.): `prompt-*` must always be the prefix (e.g., `prompt-guidelines` for general rules, `prompt-skills-guidelines` for creating/updating skills, `prompt-agents-guidelines` for agent instructions).
  - For GitHub-related skills/instructions: `github-{specific-area}-guidelines` (e.g., `github-review-guidelines`).
- **Skill Lifecycle & Granularity**: When creating or reviewing skills, explicitly evaluate whether to:
  - **Merge**: Collate smaller, overlapping, or fragmented skills into a unified capability.
  - **Break Up**: Deconstruct large, multi-purpose skills into smaller, single-responsibility skills.
- **AI Tooling / Infrastructure**:
  - Use **Docker Model Runner** (which runs `llama.cpp`) for running local models directly, rather than defaulting to `ollama`.
  - Deepseek API pricing is $0.48 per million tokens.
- **Script & Tool Efficiency**:
  - All scripts interacting with APIs (GitHub, etc.) MUST implement batching by default when dealing with multiple entities.
  - Avoid iterative per-item network calls in shell loops or high-level orchestration logic.
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
- **Architectural Decisions**:
  - **Log Rotation (macOS)**: Preferred log rotation for `launchd` agents is via shell redirection (`>`) in the `ProgramArguments` block to ensure truncation on every run, rather than using `StandardOutPath`.
  - **Service Logging (Linux)**: `systemd` services should delegate log management to `journald` via `StandardOutput=journal` instead of writing to static files.

- **PR Review & Function Hygiene**:
  - **Interactive Safety**: Always use `return` instead of `exit` within Zsh functions intended for interactive use to prevent accidental session termination.
  - **API Constraints**: GitHub PR Review API returns HTTP 422 if line-level comments are placed on lines outside the current diff hunks. Use the main review body for findings in unchanged code.
  - **Robustness**: Functions performing file operations (like `dataurl`) must verify file existence and readability using `[ -f "$file" ]` before processing to avoid malformed output and stderr noise.

## 🤖 Autonomous VM Agents (Jules)

When operating as an autonomous agent in a remote virtual machine (e.g., Jules):

1. **Active Memory and Context Retrieval**:
   - Before drafting any implementation plan or modifying code, you MUST read `./.github/instructions/memory.instructions.md` to load active user preferences, past corrections, and decision records.
   - If the task involves modifying Zsh configuration or Zsh scripts, you MUST read and follow `./.github/instructions/zsh.instructions.md`.

2. **Leverage Local Skills & Workflows**:
   - Do not write redundant scripts or reinvent existing logic. Review the custom skills in `./.github/skills/` (such as `github-review-orchestrator` and `technical-review-guidelines`) and agent workflows in `./.github/agents/` to leverage existing automation patterns and CLI utilities.

3. **Conventions & Safe Operations**:
   - Adhere strictly to the package management guidelines. Do not install packages using raw `apt` or `brew` commands. Use the modular `pkg.zsh` recipe structure.
   - Do not edit stowed files in the home directory directly. Make modifications in the source files located under the `generic/` directory.

4. **Plan Affirmation**:

   ## 🧠 Technical Memory (Durable Facts)

   ### `technical_context`
   - **Obsidian Migration**: The project has migrated Obsidian management from Zsh-based logic and Markdown rules to a standalone `bin/df.obsidian` utility with JSON validation rules. `src/zsh/apps/obsidian.zsh` now serves as a thin wrapper for this utility. Legacy Zsh functions and Markdown rule paths should be avoided.
   - **Secrets Architecture**: The `bin/df.secrets` utility currently has a regression where it performs a simple lexical merge of all `*.json` files in `assets/configs/secrets`, ignoring the previous priority-aware profile resolution logic (e.g., `work/` overriding `global/`).

   ### `correction`
   - **Obsidian Slugification**: Resolved. The regression in PR #40 where slugification was too aggressive was fixed by restoring the legacy ${note_title// /-} logic in `bin/df.obsidian`.
