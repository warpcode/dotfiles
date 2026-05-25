---
applyTo: "**/*.zsh,**/.zshrc,**/.zshenv,**/.zprofile,**/.zlogin,**/.zlogout"
---

# Zsh File Instructions

Description: Guidance for GitHub Copilot when editing Zsh configuration and Zsh script files in this repository.

Treat matching files as Zsh, not Bash.

- Do not describe Zsh files as Bash files.
- Do not generate Bash-specific guidance, Bash shebangs, or Bash-only workarounds for Zsh code unless the file explicitly requires Bash compatibility.
- Use correct Zsh syntax and semantics. Prefer native Zsh features when they improve the code, including `[[ ... ]]`, `(( ... ))`, `local`, `typeset`, arrays, parameter expansion flags, glob qualifiers, `autoload`, and `zstyle`.
- Keep the code easy for a human to read. Prefer concise code, but do not golf it into dense one-liners or obscure parameter expansions when a slightly longer form is clearer.
- Follow the Google Shell Style Guide as the baseline for basic style rules such as naming, comments, quoting, command substitution, conditionals, and function structure, but adapt those rules to Zsh rather than forcing Bash patterns: https://google.github.io/styleguide/shellguide.html
- Prefer `$(...)` over backticks.
- Quote expansions unless word splitting, globbing, or array expansion is intentionally required by Zsh semantics.
- Use descriptive function and variable names. Match this repository's existing Zsh naming style where relevant, including dotted function names such as `pkg.recipe.define` and `_zsh.init`.
- Follow the surrounding file's formatting and indentation first so edits blend into the existing codebase cleanly.

Repository-specific guidance for Zsh work:

- Keep Zsh configuration modular. Put logic in the appropriate file under `src/zsh/config/`, `src/zsh/functions/`, `src/zsh/apps/`, or `src/zsh/projects/` instead of adding large blocks directly to `src/zsh/init.zsh`.
- Never edit stowed files in `$HOME`. Edit the source files under `generic/` or `work/`.
- Use `$DOTFILES` for repository-root paths instead of hardcoded absolute paths.
- For package installation logic, use the repo's `pkg.install` and recipe system instead of direct `apt`, `brew`, or similar package-manager commands in scripts.
- **Function Exit Hygiene**: NEVER use `exit` inside Zsh functions intended for interactive use or sourcing. Always use `return <status>` (e.g., `return 1` for errors) to ensure the user's shell session is not terminated upon failure.
- **yq Compatibility in Zsh Scripts**: When calling `yq` from Zsh scripts, always target `mikefarah/yq` (v4) compatibility. Avoid `jq`-specific features such as `any()` or `from_json`. For dynamic value matching, build Zsh loop-based filter strings (e.g. `match_expr`) or export parameters individually into environment variables to be read by `yq` via `strenv()`.
- **Dynamic Backreference Evaluation**: When using `${var//(#b)pattern/repl}`, Zsh re-evaluates the `repl` string for each match. This enables patterns like `${(P)match[2]}` to dynamically look up variable names captured in the `match` array during the substitution process.
  ```zsh
  # Example: Expanding environment variables in a string
  local input='$HOME/test'
  local expanded="${input//(#b)\$(([a-zA-Z_][a-zA-Z0-9_]#)|\{([a-zA-Z_][a-zA-Z0-9_]#)\})/${(P)match[2]:-${(P)match[3]}}}"
  # If $HOME is /home/user, expanded becomes /home/user/test
  ```
