---
name: shell-scripting
description: >
  Standards, syntax, and idioms for Bash and Zsh scripting: Google Shell
  Style Guide, robust quoting/arrays, traps, setopts, and dotfiles conventions.
  Use when writing, refactoring, or reviewing shell scripts.
---

# Shell Scripting Style Guide

This skill merges the former `bash-style-guide` and `zsh-style-guide` skills
into one. It is a routing hub:

- **Shared rules** (apply to both Bash and Zsh) → `@references/style-guide.md`
- **Bash-only rules** → `@references/style-guide-bash.md`
- **Zsh-only rules** → `@references/style-guide-zsh.md`

Read only the reference(s) relevant to the file you are working on. Never load
all references upfront.

---

## Routing: Which Rules to Apply

| Context | Shebang / signal | Read |
|---|---|---|
| `.sh` file, `#!/bin/bash`, CI/cron/container script | `#!/bin/bash` | `@references/style-guide.md` + `@references/style-guide-bash.md` |
| `.zsh` file, `#!/bin/zsh`, dotfile (`.zshrc` etc.), zsh plugin/completion | `#!/bin/zsh`, `emulate`, `setopt` | `@references/style-guide.md` + `@references/style-guide-zsh.md` |
| Autoloaded zsh function file | No shebang, sourced | `@references/style-guide.md` + `@references/style-guide-zsh.md` |
| Reviewing an unknown script | Check shebang; if absent, check `setopt`/`autoload`/`BASH_SOURCE` | Route by findings |
| Choosing a shell for a new task | Portability vs feature set | `@references/style-guide-bash.md` §1 / `@references/style-guide-zsh.md` §1 |

**Default for new dotfile code:** write in Zsh with native Zsh idioms — don't
write bash-compatible code in zsh dotfiles unless portability is required. If
you need portability across machines or CI/cron, write a separate Bash script.

---

## Quick-Reference Checklist (Shared Rules)

These apply to both shells. Detailed rules and examples live in
`@references/style-guide.md`.

### When to Use Shell
- [ ] Shell only for small utilities / wrapper scripts (< ~100 lines, simple logic).
- [ ] Scripts > 100 lines or with complex logic → rewrite in Python/Go/etc.

### File Layout
- [ ] Executables: `.sh`/`.zsh` extension or none (none preferred if on `PATH`).
- [ ] Libraries: `.sh`/`.zsh` extension, not executable.
- [ ] No SUID/SGID on shell scripts — use `sudo` instead.
- [ ] File header comment describing contents.
- [ ] Order: shebang → file header → options/`setopt` → constants/`readonly` → `source` → functions → `main "$@"`.

### Formatting
- [ ] 2-space indentation, no tabs (exception: `<<-` heredocs).
- [ ] 80-character max line length. Long strings → heredoc or embedded newline.
- [ ] Pipelines: one line if it fits; otherwise pipe-per-line with `\` continuation, pipe at start of continuation line.
- [ ] `; then` / `; do` on same line as `if` / `for` / `while`.
- [ ] `else` on its own line; `fi` / `done` on their own line, aligned with opening.
- [ ] `case` alternatives indented 2 spaces from `case`; actions another 2 spaces; `;;` on its own line for multiline actions.

### Comments
- [ ] File header on every file.
- [ ] Function header on every non-trivial function (and ALL library functions), using the standard block format (Description / Globals / Arguments / Outputs / Returns).
- [ ] Comment tricky or non-obvious code sections.
- [ ] `TODO(identifier): description` format for TODOs.

### Naming
- [ ] Functions: `lower_case_with_underscores()`. Packages: `namespace::function_name()`.
- [ ] Variables: `lower_case_with_underscores`.
- [ ] Constants / env exports: `UPPER_CASE_WITH_UNDERSCORES`, declared at top.
- [ ] Source filenames: lowercase, underscores (e.g., `my_script.sh`).
- [ ] Loop variables named after what they iterate (`for zone in "${zones[@]}"`).

### Variables & Quoting
- [ ] Always quote variables: `"${var}"` not `$var`.
- [ ] Single quotes for literal strings (no substitution needed).
- [ ] `"$@"` to pass arguments; `"$*"` only when joining to a single string is the goal.
- [ ] Declare function-local variables with `local`/`typeset`. Separate the declaration from command-substitution assignment (`local` swallows `$?`).

### Features & Constructs
- [ ] `$(command)` not backticks for command substitution.
- [ ] `[[ … ]]` not `[ … ]` / `test` for conditionals.
- [ ] `(( … ))` / `$(( … ))` for arithmetic — never `let`, `expr`, or `$[…]`.
- [ ] No standalone `(( expr ))` where expr could evaluate to 0 under `set -e`/`ERR_EXIT`.
- [ ] Arrays for lists of arguments / values — never pack multiple args into a string.
- [ ] `"${array[@]}"` for quoted array expansion.
- [ ] Avoid `eval`.
- [ ] Avoid aliases in scripts — use functions instead.

### Error Handling
- [ ] All error messages → `STDERR` (`>&2`).
- [ ] Check return values: `if ! cmd` or inspect `$?`.
- [ ] Capture pipeline segment statuses immediately after the pipeline (see shell-specific reference for the array name).

### Structure
- [ ] All functions grouped together, below constants, above the main logic.
- [ ] Scripts with ≥1 function must have a `main()` function; last line: `main "$@"`.
- [ ] Local variables in every function (not bare global side-effects).

### Tooling
- [ ] Run ShellCheck on all Bash scripts; `zsh -n` syntax-checks each Zsh file individually (it only checks the first file when given multiple).

---

## Standard Function Header Template

```bash
#######################################
# Brief description of what the function does.
# Globals:
#   GLOBAL_VAR_READ
#   GLOBAL_VAR_MODIFIED
# Arguments:
#   $1 - Description of first argument.
#   $2 - Description of second argument.
# Outputs:
#   Writes result to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
my_function() {
  local arg1="$1"
  local arg2="$2"
  …
}
```

---

## Standard err() Helper

Every script that can fail should include an `err()` helper that writes to
STDERR with a timestamp. See the shell-specific reference for the exact
implementation (Bash uses `date`, Zsh uses the `zsh/datetime` module).

---

## Shell-Specific Rules

- **Bash**: `@references/style-guide-bash.md` — shebang/`set -euo pipefail`, `PIPESTATUS`,
  `readarray`, `${BASH_REMATCH}`, `${var,,}`, process substitution
  `< <(cmd)`, `declare`/`readonly`, word-splitting semantics, Bash skeleton.
- **Zsh**: `@references/style-guide-zsh.md` — `emulate -LR zsh`, `setopt`, no default word
  splitting, parameter expansion flags, string modifiers, pattern-substitution
  anchors, 1-indexed arrays, associative arrays, glob qualifiers, `print`
  vs `echo`, `zparseopts`, `autoload`/`fpath`, hooks, `zmodload`, dotfile
  layout, plugin/completion conventions, `$0` idiom, Zsh skeletons.
