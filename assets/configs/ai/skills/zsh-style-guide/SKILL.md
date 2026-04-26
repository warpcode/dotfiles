---
name: zsh-style-guide
description: >
  Apply correct Zsh style when writing, reviewing, or refactoring Zsh scripts, dotfiles, or
  plugins. Use this skill whenever the user mentions zsh, .zsh files, dotfiles (.zshrc,
  .zshenv, .zprofile, .zlogin), zsh plugins, zsh completions, or asks how to do something
  "in zsh". Also trigger for any shell task where the context indicates a zsh environment
  (e.g. the user's dotfiles repo, autoloaded functions, prompt theming, fpath management).
  Covers: when to use zsh vs bash, emulate, setopt, word-splitting differences, parameter
  expansion flags, string modifiers, pattern-substitution anchor gotchas, 1-indexed arrays,
  associative arrays, glob qualifiers, print vs echo, zparseopts, autoload/fpath, hook
  functions, zmodload, dotfile layout, plugin conventions, and completion basics. For shared
  bash/zsh conventions (naming, comments, formatting, error-handling) also consult the
  bash-style-guide skill.
---

# Zsh Shell Style Guide

For **shared conventions** (naming, comments, formatting, `[[ ]]`, `$(())`, error handling)
see the `bash-style-guide` skill. This skill covers everything **zsh-specific**.

For deep rule detail and all examples, read `references/zsh-rules.md`.

---

## Routing: When to Use This Skill vs bash-style-guide

| Context | Skill to use |
|---|---|
| `.zsh` file, `#!/bin/zsh` shebang, dotfile (`.zshrc` etc.), zsh plugin | **This skill** (+ bash-style-guide for shared rules) |
| `.sh` file, `#!/bin/bash`, CI/cron/container script | `bash-style-guide` only |
| Reviewing an unknown script | Check shebang; if absent, check `setopt`/`autoload` usage |

When writing new dotfile code, **default to zsh idioms** — don't write bash-compatible
code in your zsh dotfiles unless you explicitly need portability.

---

## Quick-Reference Checklist

### Shell Choice & Shebang
- [ ] Dotfiles / interactive config / plugins: `#!/bin/zsh`
- [ ] Scripts shared across machines or called from CI/cron: prefer `#!/bin/bash` (portability)
- [ ] Autoloaded function files: no shebang needed (they're sourced, not executed)

### Isolation & Options
- [ ] `emulate -LR zsh` at the top of every autoloaded function and plugin file
- [ ] `setopt LOCAL_OPTIONS LOCAL_TRAPS` inside functions that change options
- [ ] Scripts: `setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL`
- [ ] Dotfiles (interactive only): `setopt EXTENDED_GLOB NULL_GLOB` as needed

### Variables & Quoting
- [ ] No word-splitting by default — `$var` does NOT split on spaces (unlike bash); use `${=var}` only when splitting is intentional
- [ ] Use `"${var}"` for safety and cross-shell clarity even though unquoted is safer than bash
- [ ] Separate `local` declaration from command-substitution assignment (`local swallows $?`)
- [ ] `typeset -g` to explicitly create a global from inside a function (not a bare assignment)

### Parameter Expansion Flags
- [ ] `${(U)var}` / `${(L)var}` / `${(C)var}` for case transforms — never `tr`
- [ ] `${(j:sep:)array}` to join array → string; `${(s:sep:)str}` to split string → array
- [ ] `${(f)"$(cmd)"}` to split command output on newlines → array
- [ ] `${(q)var}` for shell-quoting (logging, safe display)
- [ ] `${(k)assoc}` / `${(v)assoc}` / `${(kv)assoc}` for assoc array iteration
- [ ] `${(u)array}` deduplicate; `${(o)array}` sort; `${(R)array}` reverse

### String Modifiers
- [ ] `${var:t}` basename, `${var:h}` dirname, `${var:r}` strip extension, `${var:e}` extension
- [ ] `${var:a}` absolute path (resolves symlinks)
- [ ] `${var:u}` uppercase, `${var:l}` lowercase
- [ ] Chain modifiers: `${var:h:t}` = dirname then basename

### ⚠ Pattern Substitution Anchors — Critical Gotcha
- [ ] `%` at start of pattern = **end-of-string anchor**, NOT a literal `%`
- [ ] `#` at start of pattern = **start-of-string anchor**, NOT a literal `#`
- [ ] To match a literal `%` or `#`: store it in a variable first, then use the variable
  ```zsh
  pct='%'; print "${str//${pct}/percent}"   # correct
  print "${str//%/percent}"                  # WRONG — % is an anchor
  ```
- [ ] See `references/zsh-rules.md §7` for all variants and workarounds

### Arrays (1-indexed!)
- [ ] First element is `$array[1]`, NOT `$array[0]`
- [ ] Last element: `$array[-1]`; slice: `$array[2,5]`
- [ ] Length: `${#array}` (same as bash)
- [ ] Intersection `${a:*b}`, difference `${a:|b}`, zip `${a:^b}`
- [ ] Always expand with `"${array[@]}"` (quoted)

### Associative Arrays
- [ ] Declare with `typeset -A mymap`
- [ ] Check key exists: `(( ${+mymap[key]} ))`
- [ ] Iterate: `for key val in "${(kv)mymap[@]}"; do …`

### Globbing
- [ ] Prefer glob qualifiers over `find` for simple cases
- [ ] `*(.)` files, `*(/)` dirs, `*(x)` executable, `*(m-7)` modified last 7 days
- [ ] `*(N)` nullglob (no error if no match) — use liberally
- [ ] `**/*(N.)` recursive files, nullglob
- [ ] `setopt EXTENDED_GLOB` for `^pattern`, `(a|b)`, `#`, `##`

### print vs echo
- [ ] Prefer `print -r -- "…"` over `echo` (raw, no escape processing, options-safe)
- [ ] `print -P "…"` for prompt-colour expansion (interactive only)
- [ ] `print -l "${array[@]}"` for one-item-per-line output

### Option Parsing
- [ ] Use `zparseopts` — not `getopts` (see skeleton below)

### Functions & Autoload
- [ ] `autoload -Uz funcname` for lazy-loaded functions
- [ ] Add your functions directory to `fpath` **before** `compinit`
- [ ] Name private helpers with `_` prefix: `_my_plugin_helper()`
- [ ] All variables `local` — use `typeset -g` only when global is genuinely needed

### Hooks
- [ ] Use `add-zsh-hook` to register hooks — never redefine hook functions directly
- [ ] Available: `precmd`, `preexec`, `chpwd`, `periodic`, `zshaddhistory`, `zshexit`

### Script Directory
- [ ] No `BASH_SOURCE` in zsh — use the `$0` idiom:
  ```zsh
  0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
  typeset -r SCRIPT_DIR="${0:A:h}"
  ```

### Dotfile Layout
- [ ] `.zshenv` — env vars only, minimal, fast (runs for every shell including scripts)
- [ ] `.zprofile` — login-time setup (`eval "$(brew shellenv)"`, etc.)
- [ ] `.zshrc` — interactive config only (aliases, prompt, plugins, completions, keybindings)
- [ ] Respect `$ZDOTDIR` for XDG layout; set it in `~/.zshenv`
- [ ] Split `.zshrc` into `conf.d/*.zsh` sourced with a glob loop

---

## Skeletons

### Executable Zsh Script

```zsh
#!/bin/zsh
#
# Brief description of what this script does.

emulate -LR zsh
setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL

zmodload zsh/datetime

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
typeset -r SCRIPT_DIR="${0:A:h}"

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
typeset -r CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  print -r -- "[$(strftime '%Y-%m-%dT%H:%M:%S%z' ${EPOCHSECONDS})]: $*" >&2
}

#######################################
# Example function.
# Arguments:
#   $1 - Input string.
# Outputs:
#   Writes lowercased string to stdout.
#######################################
process_input() {
  local input="$1"
  print -r -- "${input:l}"
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
  if (( $# < 1 )); then
    err "Usage: ${0:t} <input>"
    return 1
  fi

  local result
  result="$(process_input "$1")"
  print -r -- "${result}"
}

main "$@"
```

### Autoloaded Function File (`functions/my_func`)

```zsh
# No shebang — sourced, not executed
emulate -LR zsh
setopt LOCAL_OPTIONS LOCAL_TRAPS

#######################################
# Brief description.
# Arguments:
#   $1 - Input string.
# Outputs:
#   Writes result to stdout.
# Returns:
#   0 on success, 1 on error.
#######################################

local -a help_flag
zparseopts -D -E h=help_flag -help=help_flag || return 1

if (( ${#help_flag} )); then
  print "Usage: my_func [-h] <input>"
  return 0
fi

local input="${1:?'input required'}"
print -r -- "${input:u}"
```

### fpath + autoload Setup (in .zshrc)

```zsh
# Add before compinit
fpath=("${ZDOTDIR}/functions" "${ZDOTDIR}/completions" "${fpath[@]}")

# Autoload everything in the functions directory
for _f in "${ZDOTDIR}/functions"/*(N.x:t); do
  autoload -Uz "${_f}"
done
unset _f

autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump-${ZSH_VERSION}"
```

### conf.d Loader (in .zshrc)

```zsh
for _conf in "${ZDOTDIR}/conf.d"/*.zsh(N.); do
  source "${_conf}"
done
unset _conf
```

---

For full rule-by-rule detail with all examples, read `references/zsh-rules.md`.
