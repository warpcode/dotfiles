#!/usr/bin/env zsh
# Unit tests for dot_zsh/functions/registry.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

source "$REPO_ROOT/functions/registry.zsh" || { print -r "Failed to source registry.zsh" >&2; exit 1; }

set -e

print -r "Running registry.zsh unit tests..."

# Test 1: Define and get standard key-value pairs
registry.define test_app provider1 name="Ollama" endpoint="http://localhost:11434" api-key="sk-test-key"
v1="$(registry.get test_app provider1 name)"
if [[ "$v1" != "Ollama" ]]; then
    print -r "Test 1 Failed: name is not Ollama, got '$v1'" >&2
    exit 1
fi
v2="$(registry.get test_app provider1 endpoint)"
if [[ "$v2" != "http://localhost:11434" ]]; then
    print -r "Test 1 Failed: endpoint incorrect, got '$v2'" >&2
    exit 1
fi
v3="$(registry.get test_app provider1 api-key)"
if [[ "$v3" != "sk-test-key" ]]; then
    print -r "Test 1 Failed: hyphenated key lookup incorrect, got '$v3'" >&2
    exit 1
fi
v3_norm="$(registry.get test_app provider1 api_key)"
if [[ "$v3_norm" != "sk-test-key" ]]; then
    print -r "Test 1 Failed: normalized key lookup incorrect, got '$v3_norm'" >&2
    exit 1
fi

# Test 2: List and exists
if ! registry.exists test_app provider1; then
    print -r "Test 2 Failed: provider1 should exist" >&2
    exit 1
fi
v_list="$(registry.list test_app)"
if [[ "$v_list" != "provider1" ]]; then
    print -r "Test 2 Failed: list output incorrect, got '$v_list'" >&2
    exit 1
fi

# Test 3: Security test with shell metacharacters and single/double quotes in values
malicious_val='"; echo "HACKED"; $(whoami); `'
single_quote_val="single ' quote and \$VAR"
registry.define test_app provider2 secret="$malicious_val" note="$single_quote_val"

v_sec="$(registry.get test_app provider2 secret)"
if [[ "$v_sec" != "$malicious_val" ]]; then
    print -r "Test 3 Failed: secret value modified or mis-handled, got '$v_sec'" >&2
    exit 1
fi

v_note="$(registry.get test_app provider2 note)"
if [[ "$v_note" != "$single_quote_val" ]]; then
    print -r "Test 3 Failed: single quote value mis-handled, got '$v_note'" >&2
    exit 1
fi

# Test 3b: Security test with malicious IDs and keys
# Ensure command injection via $(...) in ID or key is blocked and not evaluated
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bad_id="id\$(touch $tmpdir/hacked_id)"
bad_key="key\$(touch $tmpdir/hacked_key)"

# Run definitions/queries inside subshell to catch rejections without aborting script
( registry.define test_app "$bad_id" "$bad_key=val" 2>/dev/null ) || true
( registry.exists test_app "$bad_id" 2>/dev/null ) || true
( registry.get test_app "$bad_id" "$bad_key" 2>/dev/null ) || true

# Assert marker files DO NOT exist FIRST (verifies zero code execution occurred)
if [[ -f "$tmpdir/hacked_id" || -f "$tmpdir/hacked_key" ]]; then
    print -r "Test 3b Failed: command injection executed during ID or key handling!" >&2
    exit 1
fi

# Secondary check: verify registry rejected the invalid inputs
if registry.define test_app "$bad_id" "$bad_key=val" 2>/dev/null; then
    print -r "Test 3b Failed: registry.define should have rejected malicious ID/key" >&2
    exit 1
fi

if registry.exists test_app "$bad_id" 2>/dev/null; then
    print -r "Test 3b Failed: registry.exists should have rejected malicious ID" >&2
    exit 1
fi

# Test 4: Duplicate defines update values without duplicating in list
registry.define test_app provider1 name="Ollama Updated"
list_count=$(registry.list test_app | wc -l | tr -d ' ')
if [[ "$list_count" != "2" ]]; then
    print -r "Test 4 Failed: provider count in list should be 2, got $list_count" >&2
    exit 1
fi
v_upd="$(registry.get test_app provider1 name)"
if [[ "$v_upd" != "Ollama Updated" ]]; then
    print -r "Test 4 Failed: provider1 name not updated, got '$v_upd'" >&2
    exit 1
fi

print -r "ALL REGISTRY TESTS PASSED SUCCESSFULLY!"
