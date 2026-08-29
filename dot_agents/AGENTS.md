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

4. **UI Stability**:
   - **Never call `update_topic` and `ask_user` in the same turn.** Set topic first, then call `ask_user` in the subsequent turn to avoid raw JSON rendering in CLI.

5. **Resource Selection & Delegation**:
   - Check whether an existing skill applies before executing and follow its guidelines.
   - Delegate high-noise exploration (broad searches, large logs, multi-file sweeps) to subagents using light models (`gemini-3.5-flash` with uninherited context).
   - **Script Execution Efficiency**: Do NOT open/read utility or helper script source code if usage and parameters are documented in `SKILL.md` or instructions. Run them directly.
   - **Skill Script Path Resolution**: When running scripts bundled with a skill (`@scripts/<name>` or `scripts/<name>`), always resolve them relative to the active skill package directory (e.g. `.github/skills/<skill-name>/scripts/<name>` or `~/.gemini/config/skills/<skill-name>/scripts/<name>`), never as `./scripts/<name>` from the workspace root.

6. **Tool Parameter Hygiene**:
   - Never pass unnecessary escaped literal quotes in tool arguments (e.g., use `"/path"`, not `"\"/path\""`).

7. **Conflict Resolution Order**: Safety > User Intent > Simplicity > Local Convention.

## 🛠️ Technical Context & Invariants

- **Source of Truth Hierarchy**: `~/.agents/AGENTS.md` is the authoritative source for durable memory. Keep workspace-only notes ephemeral.
- **Git & PR Workflows**: Delegated to `git-expert`, `github`, and `github-cli` skills. Always use a rebase strategy when pulling or syncing remote changes.
- **AI Infrastructure**: Use **Docker Model Runner** (running `llama.cpp`) for local models over `ollama`.
- **Secrets Management**: Scripts and tools MUST remain blind to the secret provider (such as `cloakenv`); rely on standard environment variables (`GITHUB_TOKEN` / `GH_TOKEN`) or native tool configs. Secret resolution is handled via `bin/df.config` (`resolve`/`hydrate`) and `bin/df.keychain`/`bin/df.keepass`.
- **Package Management Architecture**: The legacy `zinstall` logic is deprecated; use the `pkg.zsh` recipe system (`pkg.recipe.define` + `registry.zsh`).
- **Profile Configuration Hierarchy**: Base configuration is loaded first, layered with `fs.profile.load` (`df.fs profile list`) overrides via `jq` recursive merge.
- **Service Logging**: macOS `launchd` agents use shell redirection (`>`) in `ProgramArguments` for log truncation on each run; Linux `systemd` services delegate to `journald` via `StandardOutput=journal`.

