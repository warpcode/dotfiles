# Shell Style Guide — Shared Rules

Rules in this file apply to **both** Bash and Zsh. Shell-specific rules live in
`${SKILL_DIR}/references/style-guide-bash.md` and `${SKILL_DIR}/references/style-guide-zsh.md`. Where a shared rule has a different concrete form per
shell, the difference is noted inline and covered in the shell reference.

Source for Bash rules: https://google.github.io/styleguide/shellguide.html

## Table of Contents

1. [When to Use Shell](#1-when-to-use-shell)
2. [File Extensions](#2-file-extensions)
3. [SUID/SGID](#3-suid-sgid)
4. [STDOUT vs STDERR](#4-stdout-vs-stderr)
5. [Comments](#5-comments)
6. [Formatting](#6-formatting)
7. [ShellCheck](#7-shellcheck)
8. [Command Substitution](#8-command-substitution)
9. [Tests](#9-tests)
10. [Testing Strings](#10-testing-strings)
11. [Arithmetic](#11-arithmetic)
12. [Arrays](#12-arrays)
13. [Pipes to While (Subshell Gotcha)](#13-pipes-to-while-subshell-gotcha)
14. [Wildcard Expansion](#14-wildcard-expansion)
15. [Eval](#15-eval)
16. [Aliases](#16-aliases)
17. [Naming Conventions](#17-naming-conventions)
18. [Local Variables](#18-local-variables)
19. [Function Location and main](#19-function-location-and-main)
20. [Checking Return Values](#20-checking-return-values)
21. [Builtin vs External Commands](#21-builtin-vs-external-commands)

---

## 1. When to Use Shell

Shell is appropriate only for **small utilities or simple wrapper scripts**.

Rules of thumb:
- Mostly calling other utilities with little data manipulation → shell is acceptable.
- Performance matters → use something else.
- Script > ~100 lines, OR uses complex/non-straightforward control flow → **rewrite in a structured language now**. Scripts grow; rewrite early.
- Ask: can someone other than the author maintain this code?

For guidance on *which* shell to choose, see `${SKILL_DIR}/references/style-guide-bash.md` §1 or `${SKILL_DIR}/references/style-guide-zsh.md` §1.

## 2. File Extensions

| Type | Extension | Executable bit |
|---|---|---|
| Executable (goes on `PATH` or has a build rule) | `.sh` / `.zsh` or none | Yes |
| Library (sourced, not run) | `.sh` / `.zsh` | No |

When in doubt: executables either have an extension or none; libraries always
have an extension and are not executable.

## 3. SUID/SGID

**Forbidden** on shell scripts. Use `sudo` instead.

## 4. STDOUT vs STDERR

- Normal output → STDOUT.
- **All error messages → STDERR** (`>&2`).

Standard error helper (shell-specific timestamps — see `${SKILL_DIR}/references/style-guide-bash.md` §4 / `${SKILL_DIR}/references/style-guide-zsh.md` §8):

```bash
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}
```

## 5. Comments

### 5.1 File Header

Every file must start with a brief description comment:

```bash
#!/bin/bash
#
# Perform hot backups of Oracle databases.
```

Copyright and author information are optional.

### 5.2 Function Comments

Required for: any function that is not both **obvious and short**, and **all library functions** regardless of length.

Standard format:

```bash
#######################################
# Description of what the function does.
# Globals:
#   GLOBAL_VARS_USED
#   GLOBAL_VARS_MODIFIED
# Arguments:
#   $1 - first argument description
#   None (if no args)
# Outputs:
#   Writes X to stdout / STDERR.
# Returns:
#   0 on success, non-zero on error.
#######################################
function_name() { … }
```

Fields to omit if not applicable (e.g., no globals, no special return value).

### 5.3 Implementation Comments

Comment **tricky, non-obvious, interesting, or important** parts. Don't comment everything.

### 5.4 TODO Comments

Format: `# TODO(identifier): description of the remaining work`

- `identifier` = name, email, or bug reference with enough context.
- A TODO is not a commitment by that person to fix it.

## 6. Formatting

### 6.1 Indentation

- **2 spaces**. No tabs.
- Blank lines between blocks to improve readability.
- Exception: body of `<<-` heredocs may use tabs (that's their purpose).

### 6.2 Line Length

- **80 characters maximum**.
- Long literal strings → heredoc or embedded newline:

```bash
# Preferred — heredoc
cat <<END
I am an exceptionally long
string.
END

# Also OK — embedded newline
long_string="I am an exceptionally
long string."
```

### 6.3 Pipelines

```bash
# Short pipeline — one line
command1 | command2

# Long pipeline — split at pipe, pipe on continuation line, 2-space indent
command1 \
  | command2 \
  | command3 \
  | command4
```

Same rule applies to `||` and `&&` chains. Comments precede the whole pipeline.

### 6.4 Control Flow

`; then` and `; do` on the **same line** as the opening keyword:

```bash
for dir in "${dirs[@]}"; do
  if [[ -d "${dir}" ]]; then
    rm -rf "${dir}"
  else
    mkdir -p "${dir}"
  fi
done
```

- `else` on its own line.
- `fi` / `done` on their own line, aligned with the opening.
- Always write `for arg in "$@"` explicitly (don't omit `in "$@"`).

### 6.5 Case Statement

```bash
case "${expression}" in
  a)
    variable="…"
    some_command "${variable}" …
    ;;
  b) single_command ;;      # one-liner: space after ) and before ;;
  *)
    error "Unexpected: '${expression}'"
    ;;
esac
```

Rules:
- Alternatives indented 2 spaces from `case`/`esac`.
- Actions indented 2 more spaces for multiline alternatives.
- No open parenthesis before pattern.
- Avoid `;&` and `;;&`.

### 6.6 Variable Expansion

Preference order:
1. Be consistent with the surrounding code.
2. Quote all variables.
3. Use `"${var}"` (brace-delimited) for all **non-special** variables.
4. Do NOT brace-delimit single-character shell specials/positional params unless needed:

```bash
# Good
echo "Positional: $1" "$5"
echo "Specials: !=$!, -=$-, ?=$?"

# Braces needed for disambiguation or double-digit positionals
echo "${10}"
echo "${1}0${2}0"    # vs ambiguous $10$20
```

### 6.7 Quoting

- **Always quote** strings containing variables, command substitutions, spaces, or meta characters.
- Use single quotes `'…'` when **no substitution** is desired.
- Use double quotes `"…"` when substitution is needed.
- Use arrays (not strings) to store lists of arguments.
- `"$@"` to pass all arguments (preserves spacing/empty args). `"$*"` only when explicitly joining.
- Integer specials (`$?`, `$#`, `$$`, `$!`) may be quoted or not; quote named integer variables (e.g., `"${PPID}"`).

```bash
# Command substitution — always quote
flag="$(some_command "$@")"

# Shell meta chars in single quotes
echo 'Hello $$$'

# $@ vs $*
(set -- 1 "2 two"; echo "$#"; set -- "$@"; echo "$#")  # preserves count
```

## 7. ShellCheck

Run [ShellCheck](https://www.shellcheck.net/) on **all Bash scripts**, large or
small. It catches common bugs and style issues automatically.

For Zsh, ShellCheck's coverage is partial; also syntax-check with `zsh -n`.
Note: `zsh -n` only syntax-checks the **first** file argument when given
multiple — run it per file (e.g., a `for` loop or `find -exec zsh -n {} \;`).

## 8. Command Substitution

**Use `$(command)` — never backticks.**

```bash
# Good
var="$(command "$(command1)")"

# Bad — requires ugly escaping when nested
var="`command \`command1\``"
```

## 9. Tests

**Use `[[ … ]]` — not `[ … ]`, `test`, or `/usr/bin/[`.**

Why: `[[ ]]` prevents pathname expansion and word splitting; supports pattern matching (`==`) and regex (`=~`).

```bash
# Regex match
if [[ "filename" =~ ^[[:alnum:]]+name ]]; then …; fi

# Glob pattern (RHS unquoted)
if [[ "filename" == f* ]]; then …; fi
```

> Regex capture variable differs per shell: Bash uses `${BASH_REMATCH}` (see
> `${SKILL_DIR}/references/style-guide-bash.md`), Zsh uses `${match}` (see `${SKILL_DIR}/references/style-guide-zsh.md` §4).

## 10. Testing Strings

Use `-z` / `-n` rather than filler characters. Use `==` not `=`.

```bash
# Empty string
if [[ -z "${my_var}" ]]; then …; fi

# Non-empty
if [[ -n "${my_var}" ]]; then …; fi

# Equality
if [[ "${my_var}" == "val" ]]; then …; fi

# Numeric comparison — use (( )) or -lt/-gt, NOT < > inside [[ ]]
if (( my_var > 3 )); then …; fi
if [[ "${my_var}" -gt 3 ]]; then …; fi
```

## 11. Arithmetic

**Use `(( … ))` or `$(( … ))`** — never `let`, `$[ … ]`, or `expr`.

```bash
# Good
echo "$(( 2 + 2 ))"
(( i += 3 ))
if (( a < b )); then …; fi

# Bad
i=$[2 * 10]           # deprecated syntax
let i="2 + 2"         # subject to globbing/splitting
i=$(expr 4 + 4)       # external process, slow, quoting pitfalls
```

Inside `$(( … ))`, variable names do not need `${…}` — bare `var` is cleaner:

```bash
(( i += 3 ))         # not (( ${i} += 3 ))
echo "$(( hr * 3600 + min * 60 + sec ))"
```

**Caution with `set -e` / `ERR_EXIT`:** a standalone `(( expr ))` that evaluates
to 0 causes exit:

```bash
set -e
i=0
(( i++ ))   # exits here! i++ returns 0 (the old value)
```

Prefer `(( i++ )) || true` or avoid standalone `(( ))` with `set -e`.

## 12. Arrays

Use arrays to store **lists of elements** — never pack multiple values into a single string.

```bash
# Good
flags=(--foo --bar='baz')
flags+=(--greeting="Hello ${name}")
mybinary "${flags[@]}"

# Bad — quoting breaks, eval required
flags='--foo --bar=baz'
mybinary ${flags}
```

Array rules:
- Always expand with `"${array[@]}"` (quoted).
- Append with `+=( … )`.
- Avoid assigning from command output that gets split/globbed unexpectedly — use the shell-native safe idiom (see `${SKILL_DIR}/references/style-guide-bash.md` §6 or `${SKILL_DIR}/references/style-guide-zsh.md` §14/§15).
- Be aware of index base: Bash arrays are 0-indexed; **Zsh arrays are 1-indexed** (see `${SKILL_DIR}/references/style-guide-zsh.md` §8).

## 13. Pipes to While (Subshell Gotcha)

**Piping to `while` creates a subshell** — variables modified inside do not propagate back:

```bash
# BROKEN — last_line is always 'NULL' after the loop
last_line='NULL'
your_command | while read -r line; do
  last_line="${line}"
done
echo "${last_line}"  # NULL
```

Fix with the shell-appropriate idiom:
- **Bash:** process substitution `< <(your_command)` or `readarray` (`${SKILL_DIR}/references/style-guide-bash.md` §5).
- **Zsh:** process substitution `< <(your_command)` or `${(f)"$(…)"}` (`${SKILL_DIR}/references/style-guide-zsh.md` §14/§15).

> `for var in $(...)` splits on whitespace, not newlines. Prefer `while read`
> or the array-splitting idiom when lines may contain spaces.

## 14. Wildcard Expansion

Always prefix with `./` when expanding wildcards over filenames:

```bash
# Safe — won't treat -f or -r as flags
rm -v ./*

# Dangerous — rm -v * will try to rm '-f', '-r', etc.
rm -v *
```

## 15. Eval

**Avoid `eval`.**

It makes it impossible to audit what variables are set and can silently ignore
partial failures. If you think you need `eval`, you probably need an array or a
function instead.

## 16. Aliases

**Avoid aliases in scripts** — use functions instead. Aliases are cumbersome to quote/escape correctly.

```bash
# Bad alias — $RANDOM evaluated once at definition time
alias random_name="echo some_prefix_${RANDOM}"

# Good function — evaluated each call
random_name() {
  echo "some_prefix_${RANDOM}"
}

# Functions also support $@ properly
fancy_ls() {
  ls -lh "$@"
}
```

## 17. Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Functions | `lower_case_underscores()` | `my_function()` |
| Package functions | `namespace::func_name()` | `mylib::parse_args()` |
| Variables | `lower_case_underscores` | `my_var` |
| Constants / env exports | `UPPER_CASE_UNDERSCORES` | `readonly MAX_RETRIES=3` |
| Source filenames | `lower_case_underscores.sh` | `deploy_helper.sh` |
| Loop variables | Named for what they iterate | `for zone in …` |

Function rules:
- Braces on same line: `my_func() {`
- No space between name and `()`: `my_func()` not `my_func ()`
- `function` keyword is optional but must be **consistent** throughout a project.

Constant rules:
- Declare at the top of the file.
- Use `readonly` (Bash) / `typeset -r` (Zsh).
- OK to compute at runtime then immediately mark readonly:

```bash
ZIP_VERSION="$(dpkg --status zip | sed -n 's/^Version: //p')"
readonly ZIP_VERSION
```

## 18. Local Variables

**All function-level variables must be declared `local` (or `typeset`).**

- Prevents polluting the global namespace.
- **IMPORTANT:** Separate the declaration from command-substitution assignment — `local` swallows the exit code:

```bash
# Good — exit code of my_func is preserved
my_func2() {
  local my_var
  my_var="$(my_func)"
  (( $? == 0 )) || return
}

# Bad — $? is always 0 (exit code of 'local', not my_func)
my_func2() {
  local my_var="$(my_func)"
  (( $? == 0 )) || return   # always passes!
}
```

Zsh nuance: use `typeset -g` to create a global from inside a function (see
`${SKILL_DIR}/references/style-guide-zsh.md` §12); a bare assignment inside a function is a local unless declared.

## 19. Function Location and main

### Function Location

- All functions grouped together in the file, **below constants**, before any executable logic.
- Never interleave executable code between function definitions.
- Only `set`/`setopt` statements, `source`/`.` calls, and constant declarations may precede functions.

### main Function

Required when the script contains **at least one other function**:

```bash
main() {
  local input="$1"
  …
}

main "$@"   # must be the last non-comment line
```

Benefits:
- Easy to find the program entry point.
- Allows declaring variables as `local` inside main.
- Consistent with the rest of the codebase.

## 20. Checking Return Values

**Always check return values.** Never silently swallow failures.

```bash
# Direct if-check (preferred for clarity)
if ! mv "${file_list[@]}" "${dest_dir}/"; then
  echo "Unable to move ${file_list[*]} to ${dest_dir}" >&2
  exit 1
fi

# Or inspect $?
mv "${file_list[@]}" "${dest_dir}/"
if (( $? != 0 )); then
  echo "Unable to move ${file_list[*]} to ${dest_dir}" >&2
  exit 1
fi
```

### Pipeline segment statuses

Capture immediately after the pipeline — the next command overwrites it.
- Bash: `PIPESTATUS` array (`${SKILL_DIR}/references/style-guide-bash.md` §7).
- Zsh: lowercase `pipestatus` array (`${SKILL_DIR}/references/style-guide-zsh.md` §16).

Note: `[` is a command and will wipe the pipeline status array.

## 21. Builtin vs External Commands

**Prefer shell builtins over spawning external processes.**

```bash
# Good — shell builtins (fast, no fork)
addition="$(( X + Y ))"
substitution="${string/#foo/bar}"
```

Builtins to prefer over common external tools:
- Parameter expansion (`${var#prefix}`, `${var//old/new}`, case transforms) over `sed`/`awk` for simple transforms.
- `[[ =~ ]]` over `grep -oP` for regex extraction.
- `(( ))` / `$(( ))` over `expr` for arithmetic.
- `read` / the native array-splitting idiom over `cut`/`awk` for splitting lines.

Zsh extends this considerably with parameter expansion flags, string
modifiers, and glob qualifiers — see `${SKILL_DIR}/references/style-guide-zsh.md` §5, §6, §10.
