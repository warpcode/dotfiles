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

# Test 5: Dynamic function-name construction is validated (prefix and method)
# Assert on the *rejection message*, not just the exit code: a non-existent
# function also yields a non-zero status, so rc alone cannot distinguish
# "rejected by validation" from "no such function".
function test_app.fn_ok.enabled { return 0; }

if ! registry.is_enabled test_app provider1 fn_ok; then
    print -r "Test 5 Failed: valid prefix should be accepted" >&2
    exit 1
fi

check_rejected() {
    local label="$1" expected="$2"; shift 2
    local out
    out="$("$@" 2>&1 || true)"
    if [[ "$out" != *"$expected"* ]]; then
        print -r "Test 5 Failed: $label not rejected (expected '$expected', got '${out:0,60}')" >&2
        exit 1
    fi
}

check_rejected "is_enabled prefix with semicolon" "Invalid function prefix" \
    registry.is_enabled test_app provider1 'x;id'
check_rejected "is_enabled prefix with space" "Invalid function prefix" \
    registry.is_enabled test_app provider1 'a b'
check_rejected "is_enabled prefix with command substitution" "Invalid function prefix" \
    registry.is_enabled test_app provider1 '$(id -u)'
check_rejected "dispatch prefix with semicolon" "Invalid function prefix" \
    registry.call_all test_app 'x;id' enabled
check_rejected "dispatch method with semicolon" "Invalid method" \
    registry.call_all test_app fn_ok 'x;id'

# Reflected error text must stay bounded so untrusted input cannot flood logs
long_payload="$(printf 'z%.0s' {1..80})!bad"
err_msg="$(registry.define test_app "$long_payload" "k=v" 2>&1 || true)"
if (( ${#err_msg} > 80 )); then
    print -r "Test 5 Failed: error message not bounded (${#err_msg} chars)" >&2
    exit 1
fi

# --- REPLY contract -------------------------------------------------------
# The helpers return through the global REPLY, so correctness depends on no
# other REPLY writer running between a helper returning and its caller reading
# $REPLY. These cases pin that a second registry call cannot silently hand back
# the first call's value, and that a caller's REPLY is genuinely clobbered
# (documented in the registry.zsh header) rather than preserved.

registry.define test_app reply_probe alpha="A" beta="B" >/dev/null

# Interleaved calls must each yield their own value, never a stale one.
_registry.norm "second-id"; local first_reply="$REPLY"
_registry.norm "third-id";  local second_reply="$REPLY"
if [[ "$first_reply" != "second_id" || "$second_reply" != "third_id" ]]; then
    print -r "Test 6 Failed: interleaved _registry.norm returned stale REPLY ('$first_reply', '$second_reply')" >&2
    exit 1
fi

# A REPLY written by the caller before a registry call must not be mistaken for
# that call's result: read the value the helper actually produced.
REPLY="caller-sentinel"
registry.get test_app reply_probe alpha >/dev/null
if [[ "$REPLY" == "caller-sentinel" ]]; then
    print -r "Test 7 Failed: registry.get was expected to clobber REPLY but preserved it" >&2
    exit 1
fi

# ...and that clobbering must not corrupt the returned value.
if [[ "$(registry.get test_app reply_probe alpha)" != "A" ]]; then
    print -r "Test 8 Failed: registry.get returned wrong value after REPLY clobber" >&2
    exit 1
fi

# Interleaving two full public calls must keep each result independent.
if [[ "$(registry.get test_app reply_probe alpha)" != "A" ]] ||
   [[ "$(registry.get test_app reply_probe beta)"  != "B" ]]; then
    print -r "Test 9 Failed: consecutive registry.get calls returned the wrong values" >&2
    exit 1
fi

# --- Dispatch tests -------------------------------------------------------
# Test dispatch modes: call_all, call_enabled, collect, collect_enabled,
# all_true, all_false, any_true, any_false, and registry.enabled.

registry.define disp_app mod1 active="yes"
registry.define disp_app mod2 active="no"

function disp_mod.mod1.enabled { return 0; }
function disp_mod.mod2.enabled { return 1; }

# Test registry.enabled
enabled_list="$(registry.enabled disp_app disp_mod)"
if [[ "$enabled_list" != "mod1" ]]; then
    print -r "Test 10 Failed: registry.enabled should list mod1 only, got '$enabled_list'" >&2
    exit 1
fi

# Functions for call and collect
function disp_mod.mod1.greet { print -r "Hello from mod1"; }
function disp_mod.mod2.greet { print -r "Hello from mod2"; }

# Test collect_enabled: only mod1 runs
greet_enabled="$(registry.collect_enabled disp_app disp_mod greet)"
if [[ "$greet_enabled" != "Hello from mod1" ]]; then
    print -r "Test 11 Failed: collect_enabled mismatch, got '$greet_enabled'" >&2
    exit 1
fi

# Test collect (all): both mod1 and mod2 run
greet_all="$(registry.collect disp_app disp_mod greet)"
expected_greet="Hello from mod1"$'\n'"Hello from mod2"
if [[ "$greet_all" != "$expected_greet" ]]; then
    print -r "Test 12 Failed: collect mismatch, got '$greet_all'" >&2
    exit 1
fi

# Test call_all exit status with missing functions
registry.define disp_app mod3 active="yes"
# mod3 does not have .greet defined
if registry.call_all disp_app disp_mod greet >/dev/null 2>&1; then
    print -r "Test 13 Failed: call_all should fail when function is missing on an item" >&2
    exit 1
fi
if registry.collect disp_app disp_mod greet >/dev/null 2>&1; then
    print -r "Test 14 Failed: collect should fail when function is missing on an item" >&2
    exit 1
fi

# Test all_true, all_false, any_true, any_false
registry.define bool_app item1
registry.define bool_app item2

function bool_pfx.item1.is_good { return 0; }
function bool_pfx.item2.is_good { return 0; }

function bool_pfx.item1.is_bad { return 1; }
function bool_pfx.item2.is_bad { return 1; }

function bool_pfx.item1.is_mixed { return 0; }
function bool_pfx.item2.is_mixed { return 1; }

if ! registry.all_true bool_app bool_pfx is_good; then
    print -r "Test 15 Failed: all_true should succeed when all return 0" >&2
    exit 1
fi
if registry.all_true bool_app bool_pfx is_mixed; then
    print -r "Test 16 Failed: all_true should fail when one returns non-zero" >&2
    exit 1
fi

if ! registry.all_false bool_app bool_pfx is_bad; then
    print -r "Test 17 Failed: all_false should succeed when all return non-zero" >&2
    exit 1
fi
if registry.all_false bool_app bool_pfx is_mixed; then
    print -r "Test 18 Failed: all_false should fail when one returns 0" >&2
    exit 1
fi

if ! registry.any_true bool_app bool_pfx is_mixed; then
    print -r "Test 19 Failed: any_true should succeed when at least one returns 0" >&2
    exit 1
fi
if registry.any_true bool_app bool_pfx is_bad; then
    print -r "Test 20 Failed: any_true should fail when none return 0" >&2
    exit 1
fi

if ! registry.any_false bool_app bool_pfx is_mixed; then
    print -r "Test 21 Failed: any_false should succeed when at least one returns non-zero" >&2
    exit 1
fi
if registry.any_false bool_app bool_pfx is_good; then
    print -r "Test 22 Failed: any_false should fail when none return non-zero" >&2
    exit 1
fi

# Test all_true / any_true when a function is missing
registry.define bool_app item_missing
if registry.all_true bool_app bool_pfx is_good; then
    print -r "Test 23 Failed: all_true should return 1 if function missing on an item" >&2
    exit 1
fi
# For any_true, if item1 already returns 0, it short-circuits to 0 before item_missing
if ! registry.any_true bool_app bool_pfx is_good; then
    print -r "Test 24 Failed: any_true should succeed when earlier item returned 0" >&2
    exit 1
fi

print -r "ALL REGISTRY TESTS PASSED SUCCESSFULLY!"
