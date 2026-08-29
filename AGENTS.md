# Agent Instructions: warpcode/dotfiles

Chezmoi-managed dotfiles repository (shell config, CLI tools, agent assets). Always edit source files in the repo (`dot_*` dirs) — never edit stowed files in `$HOME`.

## Validation Commands (Mirrors CI)
- **Zsh**: `zsh -n <file>` (CI: `find . -name "*.zsh" -not -path "./.git/*" -exec zsh -n {} \;`)
- **Bash**: `bash -n <file>` (`install.sh`, `dot_config/mise/scripts/*.sh`, `.github/skills/*/scripts/*.sh`)
- **Shellcheck**: `shellcheck <file>` (Google Shell Style Guide baseline)
- **Python**: `python3 -m py_compile <file>`
- **mise / chezmoi**: `mise bootstrap --only packages` / `chezmoi diff` / `chezmoi verify`

## Repository Layout & Conventions
- **Chezmoi Prefixes**: `dot_*` → `~/*`, `private_dot_*` → 0600 permissions, `executable_*` → `+x`, `symlink_*` → symlink, `*.tmpl` → template.
- **Zsh Modularity**: Sourced in order: `functions/**` → `{config,apps,projects}/**` → profile init. Put logic in subdirs, not `init.zsh`.
- **Naming**: Dotted functions (`_zsh.init`, `pkg.recipe.define`, `df.*`). `df.*` binaries live in `dot_local/bin/`.
- **Mise**: `brew:` entries only in `mise.macos.toml`; platform packages in `mise.toml` `[bootstrap.packages]`; `[tools]` reserved for mise-managed versions.
- **yq**: `mikefarah/yq` (v4), not jq — avoid `any()` / `from_json`.

## Repository Pitfalls
- **Never `exit` inside zsh functions**: Use `return <status>` to prevent terminating the user's interactive shell.
- **Rules Symlink**: `dot_agents/rules/` is a symlink to `.github/instructions/`.

