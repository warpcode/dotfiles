---
name: bash-style-guide
description: >
  Apply Google's Shell Style Guide when writing, reviewing, or refactoring shell scripts (Bash).
  Use this skill whenever the user asks you to write a shell script, review or audit existing
  shell code, enforce a coding style for shell, fix shell script bugs, or asks about shell
  best practices. Also trigger when the user mentions bash scripting, .sh files, shell functions,
  or asks "how should I write this in shell". This skill covers all rules from the official
  Google Shell Style Guide: file structure, naming conventions, formatting, quoting, arrays,
  control flow, error handling, and more.
---

# Google Shell Style Guide

Full reference: https://google.github.io/styleguide/shellguide.html

When writing or reviewing shell scripts, apply every rule below. For deep reference on any
section, see `references/rules.md`.

---

## Quick-Reference Checklist

Use this when generating or auditing a script. Each item maps to a detailed rule in `references/rules.md`.

### Shell Choice & When to Use Shell
- [ ] Bash only (`#!/bin/bash`). No other shell for executables.
- [ ] Shell only for small utilities / wrapper scripts (< ~100 lines, simple logic).
- [ ] Scripts > 100 lines or with complex logic → rewrite in Python/Go/etc.

### File Layout
- [ ] Executables: `.sh` extension or no extension (no extension preferred if on `PATH`).
- [ ] Libraries: `.sh` extension, not executable.
- [ ] No SUID/SGID on shell scripts — use `sudo` instead.
- [ ] File header comment describing contents.
- [ ] Order: shebang → file header → `set` options → constants/`readonly` → `source` → functions → `main "$@"`.

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
- [ ] Constants / env exports: `UPPER_CASE_WITH_UNDERSCORES`, `readonly`, declared at top.
- [ ] Source filenames: lowercase, underscores (e.g., `my_script.sh`).
- [ ] Loop variables named after what they iterate (`for zone in "${zones[@]}"`).

### Variables & Quoting
- [ ] Always quote variables: `"${var}"` not `$var`.
- [ ] Prefer `"${var}"` over `"$var"` (brace-delimited) for all non-special vars.
- [ ] Do NOT brace-delimit single-char special params (`$1`, `$?`, `$#`, etc.) unless needed for disambiguation.
- [ ] Single quotes for literal strings (no substitution needed).
- [ ] `"$@"` to pass arguments; `"$*"` only when joining to a single string is the goal.
- [ ] Declare function-local variables with `local`. Separate `local` declaration from command-substitution assignment.

### Features & Constructs
- [ ] `$(command)` not backticks for command substitution.
- [ ] `[[ … ]]` not `[ … ]` / `test` for conditionals.
- [ ] `==` for string equality inside `[[ ]]`; `-eq`/`-lt`/`-gt` or `(( ))` for numbers.
- [ ] `-z` / `-n` for empty/non-empty string tests.
- [ ] `(( … ))` / `$(( … ))` for arithmetic — never `let`, `expr`, or `$[…]`.
- [ ] No standalone `(( expr ))` where expr could evaluate to 0 with `set -e`.
- [ ] Arrays for lists of arguments / values — never pack multiple args into a string.
- [ ] `"${array[@]}"` for quoted array expansion.
- [ ] Process substitution `< <(cmd)` or `readarray` instead of pipe-to-while (avoids subshell variable loss).
- [ ] Wildcard file expansion: use `./*` not bare `*` to guard against filenames starting with `-`.
- [ ] Avoid `eval`.
- [ ] Avoid aliases in scripts — use functions instead.
- [ ] Run ShellCheck on all scripts.

### Error Handling
- [ ] All error messages → `STDERR` (`>&2`).
- [ ] Check return values: `if ! cmd` or inspect `$?` / `PIPESTATUS`.
- [ ] Capture `PIPESTATUS` immediately — it is wiped by the next command.

### Structure
- [ ] All functions grouped together, below constants, above the main logic.
- [ ] Scripts with ≥1 function must have a `main()` function; last line: `main "$@"`.
- [ ] Local variables in every function (not bare global side-effects).

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

Every script that can fail should include:

```bash
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}
```

---

## Skeleton: New Script

```bash
#!/bin/bash
#
# Brief description of what this script does.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Example library function.
# Arguments:
#   $1 - Input string.
# Outputs:
#   Writes transformed string to stdout.
#######################################
process_input() {
  local input="$1"
  echo "${input,,}"   # lowercase via parameter expansion
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Entry point.
# Arguments:
#   All script arguments passed through.
#######################################
main() {
  if [[ $# -lt 1 ]]; then
    err "Usage: $(basename "$0") <input>"
    exit 1
  fi

  local result
  result="$(process_input "$1")"
  echo "${result}"
}

main "$@"
```

---

For the full rule-by-rule details with all examples, read `references/rules.md`.
