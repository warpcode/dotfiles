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
- **Code Review Style**: Code reviews should be formatted in `caveman-review` style (terse, actionable, one-liners formatted as `Location: problem. fix.` with severity prefixes).
- **Skill Blueprint Design**: Resources should **not** be marked as required in simple skill blueprints.
- **AI Tooling / Infrastructure**:
  - Use **Docker Model Runner** (which runs `llama.cpp`) for running local models directly, rather than defaulting to `ollama`.
  - Deepseek API pricing is $0.48 per million tokens.
- **Package Management Architecture**: The legacy `zinstall` logic is deprecated. The project is migrating towards a unified `pkg.zsh` architecture using a `recipe` dictionary format that explicitly defines methods for checking, updating, installing, and enabling packages.
