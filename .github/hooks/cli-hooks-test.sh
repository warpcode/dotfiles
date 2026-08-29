#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/src/dotfiles"

echo "== syntax checks =="
python3 -m py_compile .github/hooks/block-dangerous.py && echo "dangerous OK"
python3 -m py_compile .github/hooks/inject-cloakenv.py && echo "cloakenv OK"
python3 -c "import json; json.load(open('.github/hooks/dotfiles-hooks.json')); print('json OK')"

TMPDIR="${TMPDIR:-/tmp}"
mkdir -p "$TMPDIR/fake-mise/shims"
CLOAKENV_BIN="${CLOAKENV_BIN:-$HOME/src/cloakenv/bin/cloakenv}"
CLOAKENV_TEST_CONFIG="$TMPDIR/cloakenv-test-config.yaml"
CLOAKENV_NO_ALIAS_CONFIG="$TMPDIR/cloakenv-no-alias.yaml"
export CLOAKENV_BIN CLOAKENV_TEST_CONFIG
cat > "$CLOAKENV_TEST_CONFIG" <<'EOF'
autoload:
  - match: "^litellm(\\s+.*)?$"
    command: "litellm \\1"
EOF
: > "$CLOAKENV_NO_ALIAS_CONFIG"
printf '#!/bin/sh\nexec "${CLOAKENV_BIN}" -c "${CLOAKENV_TEST_CONFIG}" "$@"\n' > "$TMPDIR/fake-mise/shims/cloakenv"
chmod +x "$TMPDIR/fake-mise/shims/cloakenv"

run_hook() {
  local hook="$1" payload="$2"
  printf '%s\n' "$payload" | MISE_DATA_DIR="$TMPDIR/fake-mise" ".github/hooks/$hook"
}

wrapped() {
  run_hook inject-cloakenv.py "$1" | python3 -c "import json,sys; print(json.load(sys.stdin)['hookSpecificOutput']['updatedInput']['command'])"
}

echo "== T1 dangerous: raw & wrapped rm -rf -> ask, injector {} =="
run_hook block-dangerous.py '{"tool_name":"run_in_terminal","tool_input":{"command":"rm -rf foo"}}'
run_hook inject-cloakenv.py '{"tool_name":"run_in_terminal","tool_input":{"command":"rm -rf foo"}}'
run_hook block-dangerous.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cloakenv run -- rm -rf foo"}}'
run_hook inject-cloakenv.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cloakenv run -- rm -rf foo"}}'

echo "== T2 dangerous in chain: cd foo && rm -rf bar -> ask, injector {} =="
run_hook block-dangerous.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cd foo && rm -rf bar"}}'
run_hook inject-cloakenv.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cd foo && rm -rf bar"}}'

echo "== T3 env-dump in chain: cd foo && env -> deny =="
run_hook block-dangerous.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cd foo && env"}}'

echo "== T4 simple binary -> direct wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"git status"}}'

echo "== T5 && chain -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"cd foo && git status"}}'

echo "== T6 single builtin cd -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"cd foo"}}'

echo "== T7 env assignment -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"FOO=bar npm test"}}'

echo "== T8 pipe -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"cat a.txt | grep foo"}}'

echo "== T9 quoted && stays direct =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"git commit -m \"a && b\""}}'

echo "== T10 already-wrapped forms -> {} =="
run_hook inject-cloakenv.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cloakenv run -- git status"}}'
run_hook inject-cloakenv.py '{"tool_name":"run_in_terminal","tool_input":{"command":"cloakenv run -- bash -c '\''cd foo && git status'\''"}}'

echo "== T11 editFiles -> {} =="
run_hook block-dangerous.py '{"tool_name":"editFiles","tool_input":{"filePath":"foo"}}'
run_hook inject-cloakenv.py '{"tool_name":"editFiles","tool_input":{"filePath":"foo"}}'

echo "== T12 semicolon chain -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"echo a; echo b"}}'

echo "== T13 command substitution -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"echo $(date)"}}'

echo "== T14 \$VAR stays direct (no false positive) =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"echo $HOME"}}'

echo "== T15 quoted operator + var stays direct (no leak) =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"echo \"a; $GITHUB_TOKEN\""}}'

echo "== T16 unbalanced quote -> bash -c wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"echo \"unterminated"}}'

echo "== T17 echo has /bin/echo -> direct wrap =="
wrapped '{"tool_name":"run_in_terminal","tool_input":{"command":"echo foo"}}'

echo "== T18 missing alias -> {} despite stdout =="
CLOAKENV_TEST_CONFIG="$CLOAKENV_NO_ALIAS_CONFIG" run_hook inject-cloakenv.py '{"tool_name":"run_in_terminal","tool_input":{"command":"git status"}}'