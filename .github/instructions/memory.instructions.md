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
- **AI Tooling / Infrastructure**:
  - Use **Docker Model Runner** (which runs `llama.cpp`) for running local models directly, rather than defaulting to `ollama`.
  - Deepseek API pricing is $0.48 per million tokens.
- **Script & Tool Efficiency**:
  - All scripts interacting with APIs (GitHub, etc.) MUST implement batching by default when dealing with multiple entities.
  - Avoid iterative per-item network calls in shell loops or high-level orchestration logic.
  - When using `gh api graphql`, pass queries via variable injection to avoid shell quoting and path resolution issues.
- **Package Management Architecture**: The legacy `zinstall` logic is deprecated. The project is migrating towards a unified `pkg.zsh` architecture using a `recipe` dictionary format that explicitly defines methods for checking, updating, installing, and enabling packages.

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
   - In your initial implementation plan presented to the user, explicitly confirm that you have read `memory.instructions.md`, `zsh.instructions.md` (if applicable), and any relevant local skill blueprints.

