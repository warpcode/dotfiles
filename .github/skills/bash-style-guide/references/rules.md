# Shell Style Guide — Full Rule Reference

Source: https://google.github.io/styleguide/shellguide.html

## Table of Contents

1. [Which Shell to Use](#1-which-shell-to-use)
2. [When to Use Shell](#2-when-to-use-shell)
3. [File Extensions](#3-file-extensions)
4. [SUID/SGID](#4-suidsgid)
5. [STDOUT vs STDERR](#5-stdout-vs-stderr)
6. [Comments](#6-comments)
7. [Formatting](#7-formatting)
8. [ShellCheck](#8-shellcheck)
9. [Command Substitution](#9-command-substitution)
10. [Tests](#10-tests)
11. [Testing Strings](#11-testing-strings)
12. [Wildcard Expansion](#12-wildcard-expansion)
13. [Eval](#13-eval)
14. [Arrays](#14-arrays)
15. [Pipes to While](#15-pipes-to-while)
16. [Arithmetic](#16-arithmetic)
17. [Aliases](#17-aliases)
18. [Naming Conventions](#18-naming-conventions)
19. [Local Variables](#19-local-variables)
20. [Function Location and main](#20-function-location-and-main)
21. [Checking Return Values](#21-checking-return-values)
22. [Builtin vs External Commands](#22-builtin-vs-external-commands)

---

## 1. Which Shell to Use

- **Bash only** for all executable shell scripts.
- Shebang must be `#!/bin/bash` with minimal flags.
- Use `set` to configure options so the script works when called as `bash script_name`.
- No need to aim for POSIX-only / avoid "bashisms".
- Exception: constrained environments (e.g., legacy OS) may require plain Bourne shell.

## 2. When to Use Shell

Shell is appropriate only for **small utilities or simple wrapper scripts**.

Rules of thumb:
- Mostly calling other utilities with little data manipulation → shell is acceptable.
- Performance matters → use something else.
- Script > ~100 lines, OR uses complex/non-straightforward control flow → **rewrite in a structured language now**. Scripts grow; rewrite early.
- Ask: can someone other than the author maintain this code?

## 3. File Extensions

| Type | Extension | Executable bit |
|---|---|---|
| Executable (has build rule) | `.sh` | Yes |
| Executable (goes on `PATH`) | none | Yes |
| Library (sourced, not run) | `.sh` | No |

When in doubt: executables either have `.sh` or no extension; libraries always `.sh`.

## 4. SUID/SGID

**Forbidden** on shell scripts. Use `sudo` instead.

## 5. STDOUT vs STDERR

- Normal output → STDOUT.
- **All error messages → STDERR** (`>&2`).

Standard error helper:

```bash
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}
```

## 6. Comments

### 6.1 File Header

Every file must start with a brief description comment:

```bash
#!/bin/bash
#
# Perform hot backups of Oracle databases.
```

Copyright and author information are optional.

### 6.2 Function Comments

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

### 6.3 Implementation Comments

Comment **tricky, non-obvious, interesting, or important** parts. Don't comment everything.

### 6.4 TODO Comments

Format: `# TODO(identifier): description of the remaining work`

- `identifier` = name, email, or bug reference with enough context.
- A TODO is not a commitment by that person to fix it.

## 7. Formatting

### 7.1 Indentation

- **2 spaces**. No tabs.
- Blank lines between blocks to improve readability.
- Exception: body of `<<-` heredocs may use tabs (that's their purpose).

### 7.2 Line Length

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

### 7.3 Pipelines

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

### 7.4 Control Flow

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

### 7.5 Case Statement

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

### 7.6 Variable Expansion

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

### 7.7 Quoting

- **Always quote** strings containing variables, command substitutions, spaces, or meta characters.
- Use single quotes `'…'` when **no substitution** is desired.
- Use double quotes `"…"` when substitution is needed.
- Use arrays (not strings) to store lists of arguments.
- `"$@"` to pass all arguments (preserves spacing/empty args). `"$*"` only when explicitly joining.
- Optionally quote integer specials (`$?`, `$#`, `$$`, `$!`), but quote named integer vars like `PPID`.

```bash
# Command substitution — always quote
flag="$(some_command "$@")"

# Passing array flags
declare -a FLAGS=(--foo --bar='baz')
mybinary "${FLAGS[@]}"

# Shell meta chars in single quotes
echo 'Hello $$$'

# $@ vs $*
(set -- 1 "2 two"; echo "$#"; set -- "$@"; echo "$#")  # preserves count
```

## 8. ShellCheck

Run [ShellCheck](https://www.shellcheck.net/) on **all scripts**, large or small. It catches common bugs and style issues automatically.

## 9. Command Substitution

**Use `$(command)` — never backticks.**

```bash
# Good
var="$(command "$(command1)")"

# Bad — requires ugly escaping when nested
var="`command \`command1\``"
```

## 10. Tests

**Use `[[ … ]]` — not `[ … ]`, `test`, or `/usr/bin/[`.**

Why: `[[ ]]` prevents pathname expansion and word splitting; supports pattern matching (`==`) and regex (`=~`).

```bash
# Regex match
if [[ "filename" =~ ^[[:alnum:]]+name ]]; then …; fi

# Glob pattern (RHS unquoted)
if [[ "filename" == f* ]]; then …; fi

# WRONG — f* expands to files in cwd
if [ "filename" == f* ]; then …; fi
```

## 11. Testing Strings

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

## 12. Wildcard Expansion

Always prefix with `./` when expanding wildcards over filenames:

```bash
# Safe — won't treat -f or -r as flags
rm -v ./*

# Dangerous — rm -v * will try to rm '-f', '-r', etc.
rm -v *
```

## 13. Eval

**Avoid `eval`.**

It makes it impossible to audit what variables are set and can silently ignore partial failures. If you think you need `eval`, you probably need an array or a function instead.

## 14. Arrays

Use arrays to store **lists of elements** — never pack multiple values into a single string.

```bash
# Good
declare -a flags
flags=(--foo --bar='baz')
flags+=(--greeting="Hello ${name}")
mybinary "${flags[@]}"

# Bad — quoting breaks, eval required
flags='--foo --bar=baz'
mybinary ${flags}
```

Array rules:
- Declare with `declare -a`.
- Append with `+=( … )`.
- Always expand with `"${array[@]}"` (quoted).
- Avoid `declare -a files=($(ls /dir))` — command output is split/globbed unexpectedly. Use process substitution + `readarray`.

## 15. Pipes to While

**Piping to `while` creates a subshell** — variables modified inside do not propagate back.

```bash
# BROKEN — last_line is always 'NULL' after the loop
last_line='NULL'
your_command | while read -r line; do
  last_line="${line}"
done
echo "${last_line}"  # NULL

# CORRECT — process substitution
last_line='NULL'
while read -r line; do
  last_line="${line}"
done < <(your_command)
echo "${last_line}"  # correct value

# ALSO CORRECT — readarray (bash 4+)
readarray -t lines < <(your_command)
for line in "${lines[@]}"; do
  last_line="${line}"
done
```

> Note: `for var in $(...)` splits on whitespace, not newlines. Prefer `while read` or `readarray` when lines may contain spaces.

## 16. Arithmetic

**Use `(( … ))` or `$(( … ))`** — never `let`, `$[ … ]`, or `expr`.

```bash
# Good
echo "$(( 2 + 2 ))"
(( i += 3 ))
if (( a < b )); then …; fi
local -i hundred="$(( 10 * 10 ))"

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

**Caution with `set -e`:** a standalone `(( expr ))` that evaluates to 0 causes exit:

```bash
set -e
i=0
(( i++ ))   # exits here! i++ returns 0 (the old value)
```

Prefer `(( i++ )) || true` or avoid standalone `(( ))` with `set -e`.

## 17. Aliases

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

## 18. Naming Conventions

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
- Use `readonly` (and optionally `export`/`declare -x`).
- OK to compute at runtime then immediately `readonly`:

```bash
ZIP_VERSION="$(dpkg --status zip | sed -n 's/^Version: //p')"
readonly ZIP_VERSION
```

## 19. Local Variables

**All function-level variables must be declared `local`.**

- Prevents polluting the global namespace.
- **IMPORTANT:** Separate `local` declaration from command-substitution assignment — `local` swallows the exit code:

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

## 20. Function Location and main

### Function Location

- All functions grouped together in the file, **below constants**, before any executable logic.
- Never interleave executable code between function definitions.
- Only `set` statements, `source`/`.` calls, and constant declarations may precede functions.

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

## 21. Checking Return Values

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

### PIPESTATUS

Capture immediately after the pipeline — the next command overwrites it:

```bash
tar -cf - ./* | ( cd "${dir}" && tar -xf - )
return_codes=( "${PIPESTATUS[@]}" )
if (( return_codes[0] != 0 )); then do_something; fi
if (( return_codes[1] != 0 )); then do_something_else; fi
```

Note: `[` is a command and will wipe `PIPESTATUS`.

## 22. Builtin vs External Commands

**Prefer shell builtins over spawning external processes.**

```bash
# Good — bash builtins (fast, no fork)
addition="$(( X + Y ))"
substitution="${string/#foo/bar}"
if [[ "${string}" =~ foo:([0-9]+) ]]; then
  extraction="${BASH_REMATCH[1]}"
fi

# Bad — external processes (slow, quoting pitfalls)
addition="$(expr "${X}" + "${Y}")"
substitution="$(echo "${string}" | sed -e 's/^foo/bar/')"
extraction="$(echo "${string}" | sed -e 's/foo:\([0-9]\)/\1/')"
```

Builtins to prefer over common external tools:
- Parameter expansion (`${var#prefix}`, `${var//old/new}`, `${var,,}`) over `sed`/`awk` for simple transforms.
- `[[ =~ ]]` with `BASH_REMATCH` over `grep -oP` for regex extraction.
- `(( ))` / `$(( ))` over `expr` for arithmetic.
- `read` / `readarray` over `cut`/`awk` for splitting lines.
