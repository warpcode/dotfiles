#!/usr/bin/env zsh
# Unit tests for dot_zsh/config/99-command-not-found.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

source "$REPO_ROOT/config/99-command-not-found.zsh" || { print -r "Failed to source 99-command-not-found.zsh" >&2; exit 1; }

set -e

print -r "Running 99-command-not-found.zsh unit tests..."

# Test 1: Non-interactive session behavior
# In a non-interactive shell (such as this script by default), command_not_found_handler returns 127
# without attempting to reload or execute anything.
out=""
rc=0
out=$(command_not_found_handler "some_nonexistent_command" 2>&1) || rc=$?
if (( rc != 127 )); then
    print -r "Test 1 Failed: Expected return code 127 for non-interactive handler, got $rc" >&2
    exit 1
fi
if [[ "$out" != "zsh: command not found: some_nonexistent_command" ]]; then
    print -r "Test 1 Failed: Expected command not found error message, got '$out'" >&2
    exit 1
fi

# Test 2: Interactive session - command remains not found
# In zsh, interactive option can only be set via the -i shell flag
out=""
rc=0
out=$(zsh -i -c '
    source "'"$REPO_ROOT/config/99-command-not-found.zsh"'"
    path.reload() { :; }
    command_not_found_handler "definitely_not_a_real_command"
' 2>&1) || rc=$?
if (( rc != 127 )); then
    print -r "Test 2 Failed: Expected return code 127 when command is not found, got $rc" >&2
    exit 1
fi
if [[ "$out" != *"zsh: command not found: definitely_not_a_real_command"* ]]; then
    print -r "Test 2 Failed: Expected command not found error message, got '$out'" >&2
    exit 1
fi

# Test 3: Interactive session - command discovered after path.reload
# Simulate a new binary becoming available during path.reload
mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/test_dynamic_cmd" << 'EOF'
#!/bin/sh
echo "dynamic_ran:$*"
exit 42
EOF
chmod +x "$TMPDIR/bin/test_dynamic_cmd"

out=""
rc=0
out=$(zsh -i -c '
    source "'"$REPO_ROOT/config/99-command-not-found.zsh"'"
    path.reload() {
        export PATH="'"$TMPDIR/bin"':$PATH"
        rehash
    }
    command_not_found_handler "test_dynamic_cmd" "arg1" "arg2"
' 2>&1) || rc=$?
if (( rc != 42 )); then
    print -r "Test 3 Failed: Expected return code 42 from dynamically resolved command, got $rc" >&2
    exit 1
fi
if [[ "$out" != *"dynamic_ran:arg1 arg2"* ]]; then
    print -r "Test 3 Failed: Expected command output 'dynamic_ran:arg1 arg2', got '$out'" >&2
    exit 1
fi

print -r "ALL COMMAND-NOT-FOUND TESTS PASSED SUCCESSFULLY!"
