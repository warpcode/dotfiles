# warpcode/dotfiles

Chezmoi-managed dotfiles. Edit sources in `dot_*` — never touch stowed files in `$HOME`.

## Loads
- `.github/copilot-instructions.md` — Ponytail mode (auto).
- `.github/instructions/*.md` — auto-applied via `applyTo` (zsh, mise).
- `dot_agents/AGENTS.md` — guardrails + technical invariants.

## Validation
Run `./validate.sh` from the repo root before declaring any change verified — never hand-assemble
the individual checks. It mirrors CI (`lint.yml`, `python-tests.yml`): `zsh -n`, `bash -n`,
`shellcheck`, `py_compile`, zsh suites, and `unittest` discovery under `.github/skills/*/scripts`
and `tests/`. `--fast` skips the test suites, `--lint-only` runs syntax checks only, `--json`
emits a machine-readable summary.

## Destructive gates (explicit approval required)
- `chezmoi apply` / `chezmoi bootstrap --only packages`
- `rm -rf` near a symlink (`readlink`/`ls -l` first)
- `git push --force`, PR merge, network-impacting changes
- See `dot_agents/AGENTS.md` §3 for the full gate.

Approval scope: approval covers **only the actions explicitly enumerated** in the request that
sought it. A bare "proceed" / "go ahead" authorises nothing on its own — restate the list and
confirm. Approval does not carry forward to the next gate or to a newly discovered action.

## Skills
Browse `.github/skills/`. `~/.gemini/config/skills/` is a direct symlink to `.github/skills/` in
this repository; always edit and author skill sources directly under `.github/skills/`. Load the
relevant SKILL.md before executing. If a loaded skill ships a script for a step, run the script — do
not hand-write an equivalent loop.
