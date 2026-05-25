# Zsh Shell Style — Full Rule Reference

Zsh-specific rules. For naming, comments, formatting, `[[ ]]`, `$(())`, and error
handling conventions, see the `bash-style-guide` skill's `references/rules.md`.

## Table of Contents

1. [When to Use Zsh vs Bash](#1-when-to-use-zsh-vs-bash)
2. [Shebang & emulate](#2-shebang--emulate)
3. [Important setopts](#3-important-setopts)
4. [Key Differences from Bash](#4-key-differences-from-bash)
5. [Parameter Expansion Flags](#5-parameter-expansion-flags)
6. [String Modifiers](#6-string-modifiers)
7. [Pattern Substitution Anchors — Critical Gotcha](#7-pattern-substitution-anchors--critical-gotcha)
8. [Arrays — 1-Indexed](#8-arrays--1-indexed)
9. [Associative Arrays](#9-associative-arrays)
10. [Globbing & Glob Qualifiers](#10-globbing--glob-qualifiers)
11. [print vs echo](#11-print-vs-echo)
12. [Local Variables & Typed Declarations](#12-local-variables--typed-declarations)
13. [Arithmetic](#13-arithmetic)
14. [Process Substitution — =(cmd)](#14-process-substitution--cmd)
15. [Splitting Command Output into Arrays](#15-splitting-command-output-into-arrays)
16. [Testing Variable Existence](#16-testing-variable-existence)
17. [zparseopts — Option Parsing](#17-zparseopts--option-parsing)
18. [autoload & fpath](#18-autoload--fpath)
19. [Hook Functions](#19-hook-functions)
20. [zmodload](#20-zmodload)
21. [is-at-least](#21-is-at-least)
22. [Dotfile Conventions](#22-dotfile-conventions)
23. [Plugin & Function File Conventions](#23-plugin--function-file-conventions)
24. [Completion System Basics](#24-completion-system-basics)
25. [Script Directory — $0 Idiom](#25-script-directory--0-idiom)

---

## 1. When to Use Zsh vs Bash

| Use Case | Shell |
|---|---|
| Dotfiles (`.zshrc`, `.zshenv`, etc.) | Zsh |
| Zsh plugins / completions | Zsh |
| Interactive-only helpers, prompts, widgets | Zsh |
| Utility scripts shared across machines/environments | Bash (more portable) |
| Scripts called from cron, CI, containers | Bash (guaranteed present) |
| Scripts sourced in zsh but needing zsh features | Zsh with `emulate -LR zsh` guard |

**Rule:** Don't write POSIX-compatible code in your zsh dotfiles "just in case". Use the
full zsh feature set. If you need portability, write a separate bash script.

---

## 2. Shebang & emulate

Executable zsh scripts:

```zsh
#!/bin/zsh
```

For **autoloaded functions** or anything sourced in an unknown emulation mode (loaded by
a framework, plugin manager, or user config with non-default options):

```zsh
emulate -LR zsh
```

- `-L` — save and restore all options locally (like `setopt LOCAL_OPTIONS`)
- `-R` — reset to zsh defaults (undoes any user `setopt` that could interfere)

For a function that needs to isolate its own option changes:

```zsh
my_function() {
  emulate -LR zsh
  setopt LOCAL_OPTIONS LOCAL_TRAPS
  # options changed here are restored on return
}
```

---

## 3. Important setopts

### For scripts

```zsh
setopt ERR_EXIT          # exit on error (bash: set -e)
setopt PIPE_FAIL         # fail if any pipe segment fails (bash: set -o pipefail)
setopt NO_UNSET          # error on unset variable (bash: set -u)
setopt WARN_CREATE_GLOBAL  # warn when a function implicitly creates a global
setopt LOCAL_OPTIONS     # option changes in a function are local to it
setopt LOCAL_TRAPS       # trap changes in a function are local to it
```

### For interactive dotfiles only (not scripts)

```zsh
setopt EXTENDED_GLOB     # enable #, ~, ^ glob operators
setopt NULL_GLOB         # glob with no matches → empty, not error
setopt GLOB_DOTS         # include dotfiles in globs without leading .
setopt AUTO_CD           # type a directory name to cd into it
setopt CORRECT           # suggest corrections for mistyped commands
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE # don't add to history if prefixed with space
setopt SHARE_HISTORY     # share history across sessions
setopt PUSHD_SILENT      # don't print dirstack on pushd/popd
```

---

## 4. Key Differences from Bash

### Word Splitting (most important difference)

Zsh does **NOT** split unquoted variables on whitespace by default (`SH_WORD_SPLIT` is off).

```zsh
files="foo bar baz"

ls $files         # passes as ONE argument — probably wrong
ls "${files}"     # same (already one word in zsh)
ls ${=files}      # ${=var} forces word splitting (explicit opt-in)

# Better: always use arrays for lists
files=(foo bar baz)
ls "${files[@]}"  # three separate arguments, safe
```

In bash, unquoted `$files` would split on spaces automatically. Zsh's behaviour is
safer but means old bash habits of "just add quotes" don't always translate — your
real fix is to use an array.

### `BASH_SOURCE` doesn't exist

Use the `$0` idiom — see §25.

### `readarray` / `mapfile` don't exist

Use `${(f)"$(cmd)"}` — see §15.

### `local`, `typeset`, `declare` are synonymous

All three work. `typeset` is traditional zsh idiom; `local` is clearer inside functions.
Pick one per project and be consistent.

### Regex: no `${BASH_REMATCH}` — use `${match}`

```zsh
if [[ "foo123" =~ ([0-9]+) ]]; then
  print "${match[1]}"   # "123"  — zsh uses $match, not $BASH_REMATCH
fi
```

---

## 5. Parameter Expansion Flags

Zsh's `${(flags)var}` is the primary alternative to spawning `sed`/`awk`/`tr`.

### Case Conversion

```zsh
name="hello WORLD"
print "${(U)name}"    # HELLO WORLD  — all uppercase
print "${(L)name}"    # hello world  — all lowercase
print "${(C)name}"    # Hello World  — capitalise each word
```

### Joining and Splitting

```zsh
words=(foo bar baz)

# Join array → string
print "${(j:, :)words}"      # foo, bar, baz
print "${(j:\n:)words}"      # one per line

# Split string → array  (result goes to an array assignment)
csv="a,b,c"
parts=("${(s:,:)csv}")       # parts=(a b c)

# Split on newlines (common — splits command output line by line)
lines=("${(f)$(cat file)}")
lines=("${(f)"$(cmd)"}")     # double-quoting avoids glob on output
```

### Quoting & Escaping

```zsh
arg="hello world"
print "${(q)arg}"     # 'hello world'   — single-quoted (safe for eval/logging)
print "${(qq)arg}"    # "hello world"   — double-quoted
print "${(qqq)arg}"   # $'hello world'  — $'…' quoting
print "${(Q)arg}"     # remove one level of quoting
print "${(q-)arg}"    # minimal quoting (only quotes if needed)
```

### Array Operations

```zsh
arr=(c a b a c)
print "${(u)arr}"     # c a b        — deduplicate, preserving order
print "${(o)arr}"     # a a b c c    — sort ascending
print "${(O)arr}"     # c c b a a    — sort descending
print "${(Ou)arr}"    # c b a        — sort descending + unique
print "${(R)arr}"     # c a b a c    — reverse
```

### Key/Value Access for Associative Arrays

```zsh
typeset -A config=(host localhost port 5432)
print "${(k)config}"     # host port             — all keys
print "${(v)config}"     # localhost 5432        — all values
print "${(kv)config}"    # host localhost port 5432  — interleaved pairs
```

### Indirect Expansion

```zsh
varname="PATH"
print "${(P)varname}"    # expands to the value of $PATH
```

### Length and Padding

```zsh
print "${(r:10:)word}"    # right-pad to 10 chars with spaces
print "${(r:10::-)word}"  # right-pad with dashes
print "${(l:10:)word}"    # left-pad to 10 chars with spaces
```

---

## 6. String Modifiers

Zsh `:` modifiers work on both scalars and arrays.

```zsh
path="/usr/local/bin/git"
print "${path:t}"     # git             — tail (basename)
print "${path:h}"     # /usr/local/bin  — head (dirname)

file="archive.tar.gz"
print "${file:r}"     # archive.tar     — remove last extension
print "${file:e}"     # gz              — last extension only

print "${path:a}"     # absolute, resolved path (like realpath)
print "${path:u}"     # UPPERCASE
print "${path:l}"     # lowercase
```

### Chaining

```zsh
print "${path:h:t}"   # bin  — dirname then basename
```

### On arrays (modifier applied to every element)

```zsh
paths=(/usr/local/bin/git /bin/sh)
print "${paths:t}"    # git sh   — basename of each
print "${paths:h}"    # /usr/local/bin /bin
```

---

## 7. Pattern Substitution Anchors — Critical Gotcha

In `${var//pattern/replacement}`, two characters have **special meaning when they appear
at the very start of the pattern**:

| Character at start | Meaning |
|---|---|
| `#` | Anchor match to **start** of string |
| `%` | Anchor match to **end** of string |

They are **NOT** treated as literal characters.

```zsh
str="100%"

# WRONG — % anchors to end-of-string, matches empty string at end
print "${str//%/percent}"   # → "100%percent"  (not what you wanted)

# CORRECT — store the literal character in a variable first
pct='%'
print "${str//${pct}/percent}"   # → "100percent"

# ---

str="#comment"

# WRONG — # anchors to start-of-string
print "${str//#/HASH}"   # → "HASHcomment"  (removes # then prepends HASH)

# CORRECT
hash='#'
print "${str//${hash}/HASH}"   # → "HASHcomment"  (only first occurrence replaced)
```

**Rule:** whenever your substitution pattern is stored in a variable or might contain
`%` or `#` as the first character, always route through an intermediate variable.

Extended glob workaround (requires `EXTENDED_GLOB`):

```zsh
# Use (l) flag to treat pattern as literal string
print "${str//(l)%/percent}"
```

---

## 8. Arrays — 1-Indexed

**Zsh arrays start at index 1**, not 0.

```zsh
fruits=(apple banana cherry)

print "${fruits[1]}"      # apple      ← NOT fruits[0]
print "${fruits[-1]}"     # cherry     — last element
print "${fruits[-2]}"     # banana     — second to last
print "${fruits[1,2]}"    # apple banana  — slice (inclusive)
print "${#fruits}"        # 3          — length (same as bash)

# Append
fruits+=(date)

# Remove element (by index)
fruits[2]=()

# All elements (quoted)
for fruit in "${fruits[@]}"; do
  print "${fruit}"
done
```

### Array Set Operations

```zsh
a=(1 2 3 4)
b=(3 4 5 6)

print "${a:*b}"    # 3 4      — intersection
print "${a:|b}"    # 1 2      — difference (a minus b)
print "${a:^b}"    # 1 3 2 4 3 5 4 6  — zip (interleaved pairs)
```

---

## 9. Associative Arrays

```zsh
# Declare
typeset -A config

# Assign all at once
config=(
  host  localhost
  port  5432
  name  mydb
)

# Assign individual keys
config[user]=admin

# Access a value
print "${config[host]}"

# Check key existence
if (( ${+config[host]} )); then
  print "host is set to ${config[host]}"
fi

# Iterate key-value pairs
for key val in "${(kv)config[@]}"; do
  print "${key}=${val}"
done

# Iterate keys only
for key in "${(k)config[@]}"; do
  print "${key}"
done

# All keys / all values as arrays
keys=("${(k)config[@]}")
vals=("${(v)config[@]}")

# Delete a key
unset 'config[host]'

# Check if the assoc array itself is defined
(( ${+config} )) && print "config is defined"
```

---

## 10. Globbing & Glob Qualifiers

Enable with `setopt EXTENDED_GLOB` (global) or use `(#q…)` inline without the setopt.

### Recursive Glob

```zsh
print **/*.zsh          # all .zsh files recursively
print **/*(D).zsh       # including dotfiles/directories
```

### Glob Qualifiers (appended in parentheses after the pattern)

```zsh
# File type
*(.)    # regular files only
*(/)    # directories only
*(@)    # symlinks only
*(x)    # executable files

# Permissions
*(r)    # readable
*(w)    # writable
*(rw)   # readable and writable

# Time
*(m-7)  # modified in last 7 days
*(m+30) # modified more than 30 days ago
*(a-1)  # accessed in last 24 hours

# Size
*(Lk+100)  # larger than 100KB
*(Lm-1)    # smaller than 1MB

# Sorting (applied to the result)
*(om)   # sort by mtime, newest first
*(Om)   # sort by mtime, oldest first
*(oL)   # sort by size, smallest first
*(OL)   # sort by size, largest first

# Safety
*(N)    # nullglob — expand to empty if no matches, no error
*(D)    # include dotfiles

# Combine qualifiers (all must match)
**/*(N.)       # all regular files recursively, no error if none
src/**/*.ts(N.)  # all .ts under src/, no error
bin/*(x.)      # executable regular files in bin/
```

### Extended Glob Operators (require EXTENDED_GLOB)

```zsh
^pattern          # negate — files NOT matching pattern
(pat1|pat2)       # alternation
pat#              # zero or more of preceding element (like regex *)
pat##             # one or more of preceding element (like regex +)
```

### Prefer Globs Over find for Simple Cases

```zsh
# Prefer
for f in **/*.log(N.m-1); do
  process_log "$f"
done

# Fall back to find for complex predicates (-prune, -exec with multiple steps, etc.)
find . -name "*.log" -mtime -1 -not -path '*/node_modules/*' -exec process_log {} \;
```

---

## 11. print vs echo

Prefer `print` in zsh. It is more predictable, has more options, and handles edge cases
correctly.

```zsh
print "hello"              # basic output
print -r -- "hello"        # raw: no backslash escape processing; -- ends options
print -n "no newline"      # like echo -n
print -l foo bar baz       # one item per line (useful for arrays)
print -P "%F{green}OK%f"   # prompt-colour expansion (interactive use only)
print -z "ls -la"          # push to ZLE input buffer (interactive use only)
print -s "cmd"             # add to history

# STDERR
print -r -- "error message" >&2
```

Use `print -r --` as the default in scripts — it won't misinterpret `--` or backslashes
in values.

Use `echo` when generating output for POSIX consumers or when the conventional idiom
for a tool strongly favours it.

---

## 12. Local Variables & Typed Declarations

```zsh
my_function() {
  local name="$1"           # plain string
  local -i count=0          # integer — arithmetic without $(( ))
  local -r CONST="value"    # readonly local
  local -a items=()         # local array
  local -A opts=()          # local associative array
  local -l lower_var        # value is always lowercased on assignment
  local -u upper_var        # value is always uppercased on assignment
  local -F elapsed          # floating-point

  # ALWAYS separate local declaration from command-substitution assignment
  # (local swallows the exit code of the command substitution)
  local result
  result="$(some_command)"
  (( $? == 0 )) || return 1
}
```

Global declarations (constants at file top):

```zsh
typeset -gr MY_CONST="value"   # global readonly
typeset -gx EXPORTED="value"   # global + exported to environment
typeset -gA GLOBAL_MAP=()      # global associative array
```

When you need to set a global from inside a function:

```zsh
my_func() {
  typeset -g RESULT="computed"   # explicit global — not an accident
}
```

---

## 13. Arithmetic

Same rules as bash (`(( ))` and `$(( ))`). Zsh adds typed integers:

```zsh
local -i count=0
(( count++ ))        # no $((…)) needed — -i makes it an integer context
count+=5             # also works

local -F ratio
ratio=22/7           # floating point via -F
```

**`ERR_EXIT` / `set -e` caution:** `(( expr ))` evaluates to false (exit 1) when the
result is 0. This triggers `ERR_EXIT`.

```zsh
local -i i=0
(( i++ ))            # i was 0, expression is 0 → ERR_EXIT triggers!

# Safe patterns:
(( i++ )) || true
(( ++i ))            # pre-increment: result is 1 even when i was 0
(( i += 1 ))         # also safe if i is positive after
```

---

## 14. Process Substitution — `=(cmd)`

Zsh adds a second form bash doesn't have:

```zsh
# <(cmd) — named pipe / FD  (bash-compatible)
diff <(cmd1) <(cmd2)

# =(cmd) — real temporary file (seekable, can be re-read)
diff =(cmd1) =(cmd2)
vimdiff =(git show HEAD:file.txt) file.txt
```

Use `=(cmd)` when the consuming command needs a seekable file (e.g., `vimdiff`,
tools that `lseek` into the file, or tools that read it twice).

---

## 15. Splitting Command Output into Arrays

Zsh has no `readarray`/`mapfile`. The native idiom uses parameter expansion flags:

```zsh
# Split command output on newlines → array
lines=("${(f)$(cmd)}")

# With extra quoting to prevent glob expansion on the output
lines=("${(f)"$(cmd)"}")

# Split on a custom delimiter
csv_line="a,b,c"
fields=("${(s:,:)csv_line}")

# Loop safely over lines (no subshell variable loss, handles spaces in lines)
while IFS= read -r line; do
  process "$line"
done < <(cmd)

# Or with for loop (all lines in memory at once)
for line in "${(f)"$(cmd)"}"; do
  process "$line"
done
```

---

## 16. Testing Variable Existence

```zsh
# Is variable set (even if empty)?
(( ${+varname} ))
[[ -v varname ]]          # zsh 5.3+; works for arrays too: [[ -v arr[idx] ]]

# Is variable non-empty?
[[ -n "${varname}" ]]

# Is associative array key set?
(( ${+assoc[key]} ))

# Default value if unset or empty
: "${myvar:=default}"     # assign default to myvar
print "${myvar:-fallback}" # use fallback inline without assigning

# Require variable is set (error if not)
: "${REQUIRED_VAR:?'REQUIRED_VAR must be set'}"

# Length check (also works as existence test for arrays)
(( ${#myarray} > 0 )) && print "array has elements"
```

---

## 17. zparseopts — Option Parsing

`zparseopts` is the idiomatic option parser for zsh functions. Far cleaner than `getopts`.

```zsh
my_command() {
  emulate -LR zsh

  # Arrays to capture flag presence/values
  local -a opt_help opt_verbose opt_output

  zparseopts -D -E \
    h=opt_help    -help=opt_help \
    v=opt_verbose -verbose=opt_verbose \
    o:=opt_output -output:=opt_output \
    || { print -r -- "Usage: my_command [-h] [-v] [-o <file>] [args...]" >&2; return 1 }

  # $@ now contains remaining positional args (because of -D)

  if (( ${#opt_help} )); then
    print "Usage: ..."
    return 0
  fi

  local verbose=$(( ${#opt_verbose} > 0 ))

  # For flags that take arguments, value is the element after the flag in the array
  local out_file="${opt_output[-1]}"   # last value (handles repeated -o)

  print "verbose=${verbose} output=${out_file} args=${*}"
}
```

Key `zparseopts` flags:

| Flag | Meaning |
|---|---|
| `-D` | Delete parsed options from `$@` (positional args remain) |
| `-E` | Allow options mixed with positional args (stop-at-first-non-option otherwise) |
| `-M` | Allow option abbreviations (e.g. `--he` matches `--help`) |
| `flag:` | Flag takes a required argument (stored as next element in array) |
| `flag::` | Flag takes an optional argument |
| `-longflag` | Long option (zsh style: prefix with `-`) |

---

## 18. autoload & fpath

### fpath Setup (in .zshrc, before compinit)

```zsh
# Prepend your directories (later entries searched last)
fpath=("${ZDOTDIR}/functions" "${ZDOTDIR}/completions" "${fpath[@]}")

# Autoload every file in the functions directory
for _f in "${ZDOTDIR}/functions"/*(N.x:t); do
  autoload -Uz "${_f}"
done
unset _f
```

### Function File Convention

File is named exactly the same as the function. No shebang. Body is the function body:

```zsh
# File: ~/.config/zsh/functions/greet
emulate -LR zsh
local name="${1:-World}"
print -r -- "Hello, ${name}!"
```

Then: `autoload -Uz greet` / `greet Alice` → "Hello, Alice!"

### `autoload -Uz`

- `-U` — suppress alias expansion (your aliases won't break the function body)
- `-z` — use zsh-style function loading (not ksh-compatible mode)

Always use both flags together.

---

## 19. Hook Functions

Always use `add-zsh-hook` — never redefine the hook function directly, which would
break other plugins or config that registered hooks.

```zsh
autoload -Uz add-zsh-hook

# precmd — runs before each prompt draw
_my_precmd() {
  # e.g. update terminal title to current directory
  print -rn -- "\e]0;${PWD:t}\a"
}
add-zsh-hook precmd _my_precmd

# preexec — runs before each command; receives command string as $1
_my_preexec() {
  local cmd="$1"
  print -rn -- "\e]0;${cmd}\a"
}
add-zsh-hook preexec _my_preexec

# chpwd — runs after every directory change
_my_chpwd() {
  ls --color=auto
}
add-zsh-hook chpwd _my_chpwd
```

### Available hooks

| Hook | When |
|---|---|
| `precmd` | Before each prompt |
| `preexec` | Before each command is executed |
| `chpwd` | After `cd`, `pushd`, `popd` |
| `periodic` | Every `$PERIOD` seconds (if set) |
| `zshaddhistory` | Before adding a line to history |
| `zshexit` | When the shell exits |
| `zsh_directory_name` | Named directory expansion |

### Cleanup on Exit

```zsh
_my_cleanup() {
  rm -f "/tmp/my_lock_$$"
}
add-zsh-hook zshexit _my_cleanup
```

---

## 20. zmodload

Load zsh modules to unlock built-in capabilities. Always prefer modules over spawning
external processes.

```zsh
zmodload zsh/datetime    # $EPOCHSECONDS, $EPOCHREALTIME, strftime builtin
zmodload zsh/mathfunc    # sin, cos, sqrt, floor, ceil inside $(( ))
zmodload zsh/stat        # zstat builtin (faster than external stat(1))
zmodload zsh/pcre        # PCRE regex via [[ =~ ]] with pcre_compile
zmodload zsh/net/tcp     # TCP socket builtins
zmodload zsh/zle         # ZLE (already loaded in interactive shells)
zmodload zsh/complist    # coloured completion menus
zmodload zsh/parameter   # expose $parameters, $functions, $modules etc.
```

### datetime module

```zsh
zmodload zsh/datetime

print "${EPOCHSECONDS}"            # Unix timestamp (integer)
print "${EPOCHREALTIME}"           # Unix timestamp (float, microseconds)

# Format a timestamp
print "$(strftime '%Y-%m-%dT%H:%M:%S' ${EPOCHSECONDS})"

# Measure elapsed time
local -F start="${EPOCHREALTIME}"
do_work
printf "Elapsed: %.3fs\n" "$(( EPOCHREALTIME - start ))"
```

### mathfunc module

```zsh
zmodload zsh/mathfunc

print "$(( sqrt(2) ))"        # 1.4142135623730951
print "$(( floor(3.7) ))"     # 3
print "$(( ceil(3.2) ))"      # 4
```

---

## 21. is-at-least

Guard features on minimum zsh version:

```zsh
autoload -Uz is-at-least

if is-at-least 5.8; then
  # use features only in 5.8+
fi

# Error out if too old
is-at-least 5.3 || {
  print -r -- "zsh 5.3 or newer is required (have ${ZSH_VERSION})" >&2
  return 1
}
```

---

## 22. Dotfile Conventions

### File Roles

| File | When sourced | What belongs here |
|---|---|---|
| `~/.zshenv` | Every invocation (interactive, non-interactive, scripts) | `PATH`, `ZDOTDIR`, essential env vars. Keep minimal and fast. |
| `~/.zprofile` | Login shells only, before `.zshrc` | Login-time setup: `eval "$(brew shellenv)"`, `ssh-agent`, etc. |
| `~/.zshrc` | Interactive shells only | Aliases, prompt, plugins, completions, keybindings, `fpath` |
| `~/.zlogin` | Login shells, after `.zshrc` | Rarely used; post-init login tasks |
| `~/.zlogout` | Login shell exit | Cleanup |

**Rule:** `.zshenv` runs for every `zsh` invocation including scripts — keep it fast and
minimal. Never put slow commands (e.g. `brew shellenv`, `rbenv init`, `nvm`) in `.zshenv`.

### ZDOTDIR / XDG Layout

```zsh
# ~/.zshenv  — redirect everything to XDG config dir
export ZDOTDIR="${HOME}/.config/zsh"
```

With this set, zsh looks for `.zshrc`, `.zprofile`, etc. inside `~/.config/zsh/`.

### Recommended Directory Layout

```
~/.config/zsh/
├── .zshenv          (or symlink ← ~/.zshenv)
├── .zshrc           main interactive config
├── .zprofile
├── conf.d/          split config, sourced in order by .zshrc
│   ├── 00-options.zsh
│   ├── 10-env.zsh
│   ├── 20-aliases.zsh
│   ├── 30-functions.zsh
│   └── 40-prompt.zsh
├── functions/       autoloaded functions (added to fpath)
│   ├── my_util
│   └── dotfiles.noun.verb   (use dot-namespacing for dotfile utilities)
└── completions/     custom completions (added to fpath)
    └── _my_tool
```

### conf.d Loader Pattern

```zsh
# In .zshrc — source all conf.d files in order, no error if dir empty
for _conf in "${ZDOTDIR}/conf.d"/*.zsh(N.); do
  source "${_conf}"
done
unset _conf
```

### Function Naming in Dotfiles

For dotfile-specific utility functions, use dot-namespacing to signal they're internal:

```zsh
dotfiles.git.sync()   { … }
dotfiles.pkg.install() { … }
obsidian.note.create() { … }
```

This avoids namespace collisions and makes it obvious at the call site that a function
is part of your dotfiles, not a system command.

---

## 23. Plugin & Function File Conventions

```zsh
# Top of every autoloaded function or plugin file
emulate -LR zsh
setopt LOCAL_OPTIONS LOCAL_TRAPS WARN_CREATE_GLOBAL

# Private helpers: _ prefix
_plugin_internal_helper() { … }

# Public API: well-named, no prefix (or namespace:: prefix for packages)
my_plugin::main() { … }
```

Rules:
- Use `local` for ALL variables. Use `typeset -g` only when intentionally creating/updating a global.
- Do not call `compinit` from inside a plugin — let the user's `.zshrc` call it.
- Do not modify `fpath` globally from inside a plugin loaded after `compinit` — document that the plugin must be loaded before `compinit`.
- Prefix any config variables with the plugin name: `MY_PLUGIN_TIMEOUT`, not just `TIMEOUT`.

---

## 24. Completion System Basics

### Initialisation (in .zshrc)

```zsh
# 1. Extend fpath BEFORE compinit
fpath=("${ZDOTDIR}/completions" "${fpath[@]}")

# 2. Load compinit with a cache file
autoload -Uz compinit
# Only regenerate compdump once per day (speeds up shell startup)
if [[ -n "${ZDOTDIR}/.zcompdump"(N.mh+24) ]]; then
  compinit -d "${ZDOTDIR}/.zcompdump"
else
  compinit -C -d "${ZDOTDIR}/.zcompdump"  # -C skips security check on cache
fi

# 3. Style (optional, but recommended)
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive
```

### Completion Function (`completions/_my_tool`)

```zsh
#compdef my_tool

_my_tool() {
  local -a subcommands=(
    'start:Start the service'
    'stop:Stop the service'
    'status:Show current status'
  )

  _arguments \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-v --verbose)'{-v,--verbose}'[verbose output]' \
    '1: :->subcommand' \
    '*: :->args' \
    && return

  case "${state}" in
    subcommand)
      _describe 'subcommand' subcommands
      ;;
    args)
      _files
      ;;
  esac
}

_my_tool "$@"
```

---

## 25. Script Directory — $0 Idiom

Zsh has no `BASH_SOURCE`. The canonical idiom to get the current script or function
file's directory:

```zsh
# In a script
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
typeset -r SCRIPT_DIR="${0:A:h}"   # :A = resolve to absolute path; :h = dirname
```

Breakdown:
- `$ZERO` — respected by plugin managers (e.g., zinit sets `$ZERO` to the plugin file path)
- `${0:#$ZSH_ARGZERO}` — strips the shell name when zsh is invoked as a login shell (`-zsh`)
- `${(%):-%N}` — fallback: prompt expansion that gives the current function/script name

In an autoloaded function where `$0` is just the function name (not the file path):

```zsh
# Get the file path of the currently executing function
local func_file="${${funcsourcetrace[1]%:*}:A}"
local func_dir="${func_file:h}"
```
