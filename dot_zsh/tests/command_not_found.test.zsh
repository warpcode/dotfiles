#!/usr/bin/env zsh
# Unit tests for dot_zsh/config/99-command-not-found.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

source "$REPO_ROOT/config/99-command-not-found.zsh" || { print -r "Failed to source 99-command-not-found.zsh" >&2; exit 1; }

set -e

print -r "Running command-not-found unit tests..."

# Test 1: Non-interactive session behavior
# Since unit tests run non-interactively by default, [[ ! -o interactive ]] is true.
err_output="$(command_not_found_handler "nonexistent_command_123" 2>&1 || true)"
res_code=0
command_not_found_handler "nonexistent_command_123" >/dev/null 2>&1 || res_code=$?

if [[ "$res_code" -ne 127 ]]; then
    print -r "Test 1 Failed: expected exit status 127 in non-interactive session, got $res_code" >&2
    exit 1
fi

if [[ "$err_output" != "zsh: command not found: nonexistent_command_123" ]]; then
    print -r "Test 1 Failed: unexpected error output '$err_output'" >&2
    exit 1
fi

# Test 2: Interactive session simulation using zsh -i subshell
# Non-existent command in interactive mode
subshell_cmd="source '$REPO_ROOT/config/99-command-not-found.zsh'; rehash() { return 0; }; path.reload() { return 0; }; command_not_found_handler 'nonexistent_cmd_xyz'"
out_sub="$(zsh -i -c "$subshell_cmd" 2>&1 || res_code=$?)"

if [[ "$out_sub" != *"zsh: command not found: nonexistent_cmd_xyz"* ]]; then
    print -r "Test 2 Failed: expected error output, got '$out_sub'" >&2
    exit 1
fi

# Test 3: Interactive session where command is found after reload
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat <<'EOF' > "$tmpdir/found_cmd"
#!/bin/sh
echo "EXEC_SUCCESS:$1"
exit 42
EOF
chmod +x "$tmpdir/found_cmd"

subshell_cmd3="source '$REPO_ROOT/config/99-command-not-found.zsh'; rehash() { return 0; }; path.reload() { export PATH='$tmpdir:\$PATH'; }; command_not_found_handler 'found_cmd' 'arg1'"
res_code3=0
out_sub3="$(zsh -i -c "$subshell_cmd3" 2>&1)" || res_code3=$?

if [[ "$res_code3" -ne 42 ]]; then
    print -r "Test 3 Failed: expected return status 42, got $res_code3" >&2
    exit 1
fi

if [[ "$out_sub3" != *"EXEC_SUCCESS:arg1"* ]]; then
    print -r "Test 3 Failed: unexpected output '$out_sub3'" >&2
    exit 1
fi

print -r "ALL COMMAND-NOT-FOUND TESTS PASSED SUCCESSFULLY!"
