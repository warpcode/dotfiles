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
