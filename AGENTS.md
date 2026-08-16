# Agent Instructions

This is a **chezmoi-managed dotfiles repository** (`warpcode/dotfiles`): shell config, tools, and AI agent assets managed across machines. Edit source files in the repo (`dot_*` dirs) — never edit stowed files in `$HOME`.

## You MUST
- Load `.github/copilot-instructions.md` (Ponytail lazy-senior-dev mode) and follow it.
- Load all `.md` files from `.github/instructions/` and follow them when editing matching files.
- Follow `dot_agents/AGENTS.md` for behavioral guardrails and technical preferences.

## Validate changes (mirrors CI)
- **Zsh**: `zsh -n <file>` — per file (`zsh -n` only checks the first arg). CI: `find . -name "*.zsh" -not -path "./.git/*" -exec zsh -n {} \;`
- **Bash**: `bash -n <file>` (`install.sh`, `dot_config/mise/scripts/*.sh`, `.github/skills/*/scripts/*.sh`)
- **Shellcheck**: `shellcheck <file>` (Google Shell Style Guide baseline)
- **Python**: `python3 -m py_compile <file>`
- **mise**: `mise install` / `mise bootstrap --only packages`
- **chezmoi**: `chezmoi diff` / `chezmoi apply` / `chezmoi verify`

## Layout (chezmoi conventions)
- `dot_<name>` → hidden file/dir in `$HOME` (`dot_zsh/` → `~/.zsh`, `dot_config/` → `~/.config`, `dot_agents/` → `~/.agents`)
- `private_dot_*` → 0600 perms (secrets); `executable_` → exec bit; `symlink_` → symlink; `.tmpl` → chezmoi/gomplate template
- `dot_zsh/init.zsh` sources in order: `functions/**` → `{config,apps,projects}/**` → profile init. Keep config modular — put logic in the right subdir, not `init.zsh`.

## Key conventions
- **Packages**: use the `pkg.zsh` recipe system (`pkg.recipe.define` + `registry.zsh`), never raw `apt`/`brew` in scripts. Legacy `zinstall` is deprecated.
- **Naming**: dotted functions (`_zsh.init`, `pkg.recipe.define`, `df.*`). `df.*` are standalone executables in `dot_local/bin/`.
- **mise**: `brew:` only in `mise.macos.toml`; platform packages in main `mise.toml` `[bootstrap.packages]`; `[tools]` only for mise-managed versioned tools.
- **yq**: `mikefarah/yq` (v4), not jq — avoid `any()`/`from_json`.
- **AI scripts**: default to token-efficient Markdown summaries; implement `--raw`; agents must NOT use `--raw` during normal orchestration.
- **Profiles**: `DOTFILES_PROFILE` (default) selects config under `assets/configs/`; override chain base → global → profile.

## Pitfalls
- **Never** `exit` inside zsh functions — use `return <status>` (kills the user's shell).
- **Never** use full home paths in commands — use `$HOME`/`~` (some services redact them).
- **Symlink safety**: never `rm -rf` through a symlink — `readlink`/`ls -l` first.
- **Secrets**: scripts stay blind to the secret provider; rely on env vars (`GITHUB_TOKEN`/`GH_TOKEN`) or `df.config resolve`/`df.keychain`.
- `dot_agents/rules/` is a symlink to `.github/instructions/`.
- Mark deliberate simplifications with a `ponytail:` comment naming the ceiling + upgrade path.

## Skills
- `.github/skills/`: `cli-to-skill`, `email-classifier`, `git-expert`, `github-cli`, `jules-cli`, `shell-scripting`
- `dot_agents/skills/`: `prompt-engineering`, `technical-review-guidelines`, `jira-tasks`, `agentic-architecture`, `prompt-skills-guidelines`, and more
- Load the relevant skill before executing (see `dot_agents/AGENTS.md` resource-selection rules).
