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

## 🛠️ Technical Context & Preferences

- **Git Workflow**:
  - All GitHub Actions MUST pass before any merge.
  - Prefer squash-and-merge for pull requests.
  - Remote branches MUST be deleted immediately after merging.
- **Code Review Style**:
  - **Tone**: Short, professional, and to the point. Never use "LGTM" or unnecessary affirmations. Do not repeat yourself.
  - **Approval**: If approving a pull request, NEVER add NEW comments to files. Do not provide a summary if there is nothing new to add; just ask to approve.
  - **Replies**: Only reply if needed (with user approval). Give a thumbs up (👍) ONLY if the developer replied saying they fixed a requested change.
  - **Resolution**: If no further questions or modifications are required, mark the thread as resolved. If the developer asks a question, alert the user for a response.
  - **Format**: Use line-level comments for specific issues and file-level comments for file-wide concerns. If nothing is wrong, do not add any comments. Comments MUST NOT use 'caveman' style. Use plain English to describe the issue, explain why it is a problem, and suggest a potential solution.
- **Skill Blueprint Design**: Resources should **not** be marked as required in simple skill blueprints.
- **AI Tooling / Infrastructure**:
  - Use **Docker Model Runner** (which runs `llama.cpp`) for running local models directly, rather than defaulting to `ollama`.
  - Deepseek API pricing is $0.48 per million tokens.
- **Package Management Architecture**: The legacy `zinstall` logic is deprecated. The project is migrating towards a unified `pkg.zsh` architecture using a `recipe` dictionary format that explicitly defines methods for checking, updating, installing, and enabling packages.
