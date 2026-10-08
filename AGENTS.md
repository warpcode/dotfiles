# warpcode/dotfiles

Chezmoi-managed dotfiles. Edit sources in `dot_*` — never touch stowed files in `$HOME`.

## Loads
- `.github/copilot-instructions.md` — Ponytail mode (auto).
- `.github/instructions/*.md` — auto-applied via `applyTo` (zsh, mise).
- `dot_agents/AGENTS.md` — guardrails + technical invariants.

## Validation
Mirror CI: `zsh -n`, `bash -n`, `shellcheck`, `python3 -m py_compile`. Full list in `dot_agents/AGENTS.md` §Technical Context.

## Destructive gates (explicit approval required)
- `chezmoi apply` / `chezmoi bootstrap --only packages`
- `rm -rf` near a symlink (`readlink`/`ls -l` first)
- `git push --force`, PR merge, network-impacting changes
- See `dot_agents/AGENTS.md` §3 for the full gate.

Approval scope: approval covers **only the actions explicitly enumerated** in the request that
sought it. A bare "proceed" / "go ahead" authorises nothing on its own — restate the list and
confirm. Approval does not carry forward to the next gate or to a newly discovered action.

## Skills
Browse `.github/skills/`. Load the relevant SKILL.md before executing. If a loaded skill ships a
script for a step, run the script — do not hand-write an equivalent loop.
