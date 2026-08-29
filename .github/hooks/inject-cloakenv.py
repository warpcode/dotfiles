#!/usr/bin/env python3
"""PreToolUse secrets-injector: wrap safe commands with `cloakenv run --`.

Runs SECOND in the PreToolUse chain (see dotfiles-hooks.json). Skips dangerous
commands (handled by block-dangerous.py) and already-wrapped commands.
Self-contained: shares no code with block-dangerous.py.
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys

# A command that already carries the cloakenv wrapper (optionally with the
# PATH= prefix the injector adds).
WRAPPED = re.compile(r"(^|[;&|]\s*)(PATH=\S+\s+)?cloakenv\s+run\s+--")

# Shell builtins with no standalone binary. cloakenv execs a binary, so these
# can't be wrapped directly — commands whose first word is one of these are
# wrapped via `bash -c` instead. Builtins that DO have a standalone binary
# (echo, printf, test, [, true, false, kill) are excluded: wrapping them
# directly also keeps `echo $VAR` from expanding inside a wrapped bash where
# injected secrets would leak into model-visible output.
SHELL_BUILTINS = frozenset({
    "cd", "export", "source", ".", "alias", "unalias", "set", "unset", "shift",
    "local", "readonly", "declare", "typeset", "pushd", "popd", "dirs", "jobs",
    "fg", "bg", "wait", "exit", "return", "trap", "umask", "ulimit", "eval",
    "exec", "builtin", "command", "type", "hash", "help", "history", "logout",
    "suspend", "select", "coproc", "mapfile", "readarray", "compgen", "complete",
    "compopt", "bind", "caller", "enable", "fc", "shopt", "times", "let",
    "getopts", "read",
})

# Characters that make a token a shell operator when the whole token is made
# of them (shlex with punctuation_chars=True splits these into standalone
# tokens; `$` only appears standalone before `(`, i.e. command substitution).
_OPERATOR_CHARS = set(";&|()<>$")


def extract_command(payload):
    """Return (field, command) from a PreToolUse payload, or (None, None)."""
    tool_input = payload.get("tool_input", {})
    if not isinstance(tool_input, dict):
        return None, None
    field = (
        "command"
        if isinstance(tool_input.get("command"), str) and tool_input.get("command").strip()
        else "input"
    )
    command = tool_input.get(field, "")
    if not isinstance(command, str) or not command.strip():
        return None, None
    return field, command


def is_wrapped(command):
    return bool(WRAPPED.search(command))


def needs_shell(command):
    """True if the command needs `bash -c` wrapping (chains, builtins, env assignments).

    Tokenizes with shlex (posix + punctuation_chars) so quotes and escapes are
    handled correctly: operators inside quotes stay inside a word, top-level
    operators surface as standalone tokens. A token that is entirely operator
    characters is a real top-level operator; `$(`/backticks are also detected
    inside double quotes (they're command substitution there too).
    """
    if "\n" in command:
        return True  # newline is a command separator
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return True  # unbalanced quotes — let bash -c handle it
    if not tokens:
        return False
    if any(t and all(c in _OPERATOR_CHARS for c in t) for t in tokens):
        return True  # top-level operator: ; | & && || < > >> ( ) $ ...
    if any("$(" in t or "`" in t for t in tokens):
        return True  # command substitution (also inside double quotes)
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tokens[0]):
        return True  # env assignment prefix: VAR=val cmd
    return tokens[0] in SHELL_BUILTINS


def wrap_command(command, prefix):
    """Wrap a command with cloakenv, using `bash -c` when shell semantics are needed.

    Simple binary commands wrap directly (`cloakenv run -- <cmd>`); anything
    with chains, builtins, env assignments or subshells wraps the whole thing
    via `bash -c` so every subcommand gets the injected secrets.
    """
    if needs_shell(command):
        quoted = command.replace("'", "'\\''")
        return prefix + "cloakenv run -- bash -c '" + quoted + "'"
    return prefix + "cloakenv run -- " + command


def mise_shims_dir():
    """Best-effort resolve of the mise shims directory (where tool shims live)."""
    data_dir = os.environ.get("MISE_DATA_DIR")
    if not data_dir:
        mise = shutil.which("mise")
        if mise:
            try:
                out = subprocess.run(
                    [mise, "data-dir"], capture_output=True, text=True, timeout=5
                ).stdout.strip()
                if out:
                    data_dir = out
            except Exception:
                pass
    if not data_dir:
        data_dir = os.path.join(os.path.expanduser("~"), ".local", "share", "mise")
    return os.path.join(data_dir, "shims")


def cloakenv_prefix(command):
    """Return a shell prefix when this command matches a configured cloakenv alias.

    Prefers the mise shims dir (works without `mise activate`); falls back to
    relying on PATH. Returns None when cloakenv is unavailable, the alias system
    errors out, or the command does not match any configured alias — in any of
    those cases the hook leaves the command unwrapped.
    """
    shims = mise_shims_dir()
    cloakenv = os.path.join(shims, "cloakenv")
    if os.path.isfile(cloakenv):
        new_path = shims + os.pathsep + os.environ.get("PATH", "")
        prefix = "PATH=" + shlex.quote(new_path) + " "
    else:
        cloakenv = shutil.which("cloakenv")
        if not cloakenv:
            return None
        prefix = ""

    try:
        result = subprocess.run(
            [cloakenv, "internal", "match-alias", "--", command],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return prefix if result.returncode == 0 else None


try:
    payload = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    print("{}")
    raise SystemExit(0)

field, command = extract_command(payload)
if field is None:
    print("{}")
    raise SystemExit(0)

# Already wrapped (safe): no modification needed; let the normal permission flow decide.
if is_wrapped(command):
    print("{}")
    raise SystemExit(0)

# Transparently wrap the command so secrets are injected at runtime only.
# match-alias also gates wrapping on whether the command matches a configured
# alias — when nothing matches, skip wrapping so unrelated commands are
# untouched. Deliberately omit permissionDecision so VS Code's normal
# allow/deny rules still gate the tool call (ponytail: don't reimplement
# the agent's policy).
prefix = cloakenv_prefix(command)
if prefix is None:
    # cloakenv not installed, errored, or command matches no alias — leave
    # the command alone in either case.
    print("{}")
    raise SystemExit(0)

updated = dict(payload["tool_input"])
updated[field] = wrap_command(command, prefix)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "updatedInput": updated,
        "additionalContext": "Command was automatically wrapped with 'cloakenv run --' by security policy so secret environment variables are injected at runtime and never appear in model-visible context. It must be run outside of the sandbox."
    }
}))