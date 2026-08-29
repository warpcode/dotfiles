# Agent Instructions: warpcode/dotfiles

Chezmoi-managed dotfiles repository (shell config, CLI tools, agent assets). Always edit source files in the repo (`dot_*` dirs) — never edit stowed files in `$HOME`.

## You MUST
- Load `.github/copilot-instructions.md` (Ponytail lazy-senior-dev mode) and follow it.
- Load all `.md` files from `.github/instructions/` and follow them when editing matching files.
- Follow `dot_agents/AGENTS.md` for behavioral guardrails and technical preferences.

## Validation Commands (Mirrors CI)
- **Zsh**: `zsh -n <file>` (CI: `find . -name "*.zsh" -not -path "./.git/*" -exec zsh -n {} \;`)
- **Bash**: `bash -n <file>` (`install.sh`, `dot_config/mise/scripts/*.sh`, `.github/skills/*/scripts/*.sh`)
- **Shellcheck**: `shellcheck <file>` (Google Shell Style Guide baseline)
- **Python**: `python3 -m py_compile <file>`
- **Read-only chezmoi**: `chezmoi diff` / `chezmoi verify` (safe to run anytime).
- **Mutating chezmoi**: `chezmoi apply` / `chezmoi bootstrap --only packages` — require explicit user approval per `dot_agents/AGENTS.md` §3.

## Repository Layout & Conventions
- **Chezmoi Prefixes**: `dot_*` → `~/*`, `private_dot_*` → 0600 permissions, `executable_*` → `+x`, `symlink_*` → symlink, `*.tmpl` → template.
- **Zsh Modularity**: `dot_zsh/init.zsh` sources in order: `functions/**` → `{config,apps,projects}/**` → profile init. Put logic in subdirs, not `init.zsh`.
- **Naming**: Dotted functions (`_zsh.init`, `pkg.recipe.define`, `df.*`). `df.*` binaries live in `dot_local/bin/`.
- **Mise**: `brew:` entries only in `mise.macos.toml`; platform packages in `mise.toml` `[bootstrap.packages]` (apt/brew etc. installed during bootstrap); `[tools]` reserved for mise-managed versioned runtimes.
- **yq**: `mikefarah/yq` (v4), not jq — avoid `any()` / `from_json`.

## Key Conventions
- **Packages**: use the `pkg.zsh` recipe system (`pkg.recipe.define` + `registry.zsh`), never raw `apt`/`brew` in scripts. Legacy `zinstall` is deprecated.
- **AI scripts**: default to token-efficient Markdown summaries; implement `--raw`; agents must NOT use `--raw` during normal orchestration.
- **Profiles**: `DOTFILES_PROFILE` (default) selects config under `assets/configs/`; override chain base → global → profile.

## Pitfalls
- **Never** `exit` inside zsh functions — use `return <status>` (kills the user's shell).
- **Never** use full home paths in commands — use `$HOME`/`~` (some services redact them).
- **Symlink safety**: never `rm -rf` through a symlink — `readlink`/`ls -l` first; delete the symlink itself, not the target contents.
- **Secrets**: scripts stay blind to the secret provider; rely on env vars (`GITHUB_TOKEN`/`GH_TOKEN`) or `df.config resolve`/`df.keychain`.
- `dot_agents/rules/` is a symlink to `.github/instructions/`.
- Mark deliberate simplifications with a `ponytail:` comment naming the ceiling + upgrade path.

## Skills
- `.github/skills/`: `ai-authoring-*`, `email-classifier`, `git-expert`, `github`, `github-cli`, `google-antigravity-cli`, `google-jules-api`, `shell-scripting`
- Load the relevant skill before executing (see `dot_agents/AGENTS.md` resource-selection rules).
