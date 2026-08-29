# Bash-Specific Rules

Rules unique to Bash. Apply together with the shared rules in `@references/style-guide.md`.
For Zsh-specific rules, see `@references/style-guide-zsh.md`.

## Table of Contents

1. [When to Use Bash vs Zsh](#1-when-to-use-bash-vs-zsh)
2. [Shebang & Options](#2-shebang--options)
3. [Word Splitting Semantics](#3-word-splitting-semantics)
4. [err() Helper](#4-err-helper)
5. [Process Substitution & readarray](#5-process-substitution--readarray)
6. [Arrays & declare](#6-arrays--declare)
7. [PIPESTATUS](#7-pipestatus)
8. [Regex: BASH_REMATCH](#8-regex-bash_rematch)
9. [Case Transforms & Parameter Expansion](#9-case-transforms--parameter-expansion)
10. [Script Directory — BASH_SOURCE](#10-script-directory--bash_source)
11. [Constant Declaration](#11-constant-declaration)
12. [Skeleton: New Bash Script](#12-skeleton-new-bash-script)

---

## 1. When to Use Bash vs Zsh

- **Bash only** for all executable shell scripts that must run anywhere (CI,
  cron, containers, other machines).
- Shebang must be `#!/bin/bash` with minimal flags.
- Use `set` to configure options so the script works when called as `bash script_name`.
- No need to aim for POSIX-only / avoid "bashisms".
- Exception: constrained environments (e.g., legacy OS) may require plain Bourne shell.
- For interactive dotfiles, plugins, or zsh-feature code, prefer Zsh — see `@references/style-guide-zsh.md` §1.

## 2. Shebang & Options

```bash
#!/bin/bash
#
# Brief description of what this script does.

set -euo pipefail
```

- `set -e` — exit on error.
- `set -u` — error on unset variable.
- `set -o pipefail` — fail if any pipe segment fails.
- `set -x` — optional, trace commands while debugging.

See also the arithmetic caution in `@references/style-guide.md` §11: a standalone
`(( expr ))` that evaluates to 0 will exit under `set -e`.

## 3. Word Splitting Semantics

Bash **does** split unquoted variables on whitespace. Quote variables unless
splitting is explicitly intended:

```bash
files="foo bar baz"
ls $files         # splits into three args (often wrong)
ls "${files}"     # one arg — correct for a single path
```

For real lists, always use arrays (§6), not space-delimited strings.

## 4. err() Helper

```bash
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}
```

## 5. Process Substitution & readarray

### Process substitution (avoids pipe-to-while subshell)

```bash
last_line='NULL'
while read -r line; do
  last_line="${line}"
done < <(your_command)
echo "${last_line}"  # correct value
```

### readarray / mapfile (bash 4+)

```bash
readarray -t lines < <(your_command)
for line in "${lines[@]}"; do
  last_line="${line}"
done
```

`readarray` is also the safe replacement for `declare -a files=($(ls /dir))`,
which splits and globs unexpectedly.

## 6. Arrays & declare

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

- Declare with `declare -a`.
- Append with `+=( … )`.
- Always expand with `"${array[@]}"` (quoted).
- 0-indexed: first element is `"${array[0]}"`.
- `"${array[@]}"` to pass arguments; `"${array[*]}"` only when joining to a single string.

## 7. PIPESTATUS

Capture immediately after the pipeline — the next command overwrites it:

```bash
tar -cf - ./* | ( cd "${dir}" && tar -xf - )
return_codes=( "${PIPESTATUS[@]}" )
if (( return_codes[0] != 0 )); then do_something; fi
if (( return_codes[1] != 0 )); then do_something_else; fi
```

Note: `[` is a command and will wipe `PIPESTATUS`.

## 8. Regex: BASH_REMATCH

```bash
if [[ "${string}" =~ foo:([0-9]+) ]]; then
  extraction="${BASH_REMATCH[1]}"
fi
```

## 9. Case Transforms & Parameter Expansion

Prefer parameter expansion over external tools for simple transforms:

```bash
# Lowercase / uppercase (bash 4+)
lower="${var,,}"
upper="${var^^}"

# Prefix / suffix removal and substitution
substitution="${string/#foo/bar}"
stripped="${string#prefix}"
```

Over `sed`/`awk`/`expr` for simple transforms:

```bash
# Bad — external processes (slow, quoting pitfalls)
substitution="$(echo "${string}" | sed -e 's/^foo/bar/')"

# Good — builtin
substitution="${string/#foo/bar}"
```

## 10. Script Directory — BASH_SOURCE

```bash
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

Use `BASH_SOURCE[0]`, not `$0` — `$0` is unreliable when the script is sourced
or invoked via a symlink/PATH. (Zsh has no `BASH_SOURCE`; it uses the `$0`
idiom — see `@references/style-guide-zsh.md` §25.)

## 11. Constant Declaration

Declare constants at the top of the file with `readonly`:

```bash
readonly MAX_RETRIES=3

# OK to compute at runtime then immediately mark readonly
ZIP_VERSION="$(dpkg --status zip | sed -n 's/^Version: //p')"
readonly ZIP_VERSION
```

`export` / `declare -x` only when the value must be visible to child processes.

## 12. Skeleton: New Bash Script

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
