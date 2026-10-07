#!/usr/bin/env zsh

# Mock registry behaviour for testing.
# This mock is deliberately *stateful*: it records what registry.define was
# given and only resolves lookups for ids that were actually registered,
# normalising ids the same way the real registry does ('-' -> '_').
# A stub that answered unconditionally would hide the case where a provider
# registers its functions under a different name than the registry key.
typeset -gA _TEST_PROVIDERS
_TEST_BASE_URL="http://fake-base-url"

registry.define() {
    local ns="$1" id="$2"; shift 2
    [[ "$ns" == "ai_provider" ]] || return 0
    id="${id//-/_}"
    _TEST_PROVIDERS["$id/base_url"]="$_TEST_BASE_URL"
    local pair
    for pair in "$@"; do
        [[ "$pair" == *=* ]] || continue
        _TEST_PROVIDERS["$id/${pair%%=*}"]="${pair#*=}"
    done
    return 0
}

registry.get() {
    [[ "$1" == "ai_provider" ]] || return 1
    local id="${2//-/_}"
    # NOTE: the subscript must stay quoted -- zsh yields an empty value for an
    # unquoted subscript containing '/'.
    [[ -n "${_TEST_PROVIDERS["$id/$3"]+set}" ]] || return 1
    print -r -- "${_TEST_PROVIDERS["$id/$3"]}"
}
registry.list() { print -r -- "${(@)_TEST_PROVIDERS}"; }
registry.is_enabled() { return 0; }
df.cache() { return 0; }

# Mock downstream tools to prevent real network calls and test data flow
curl() { echo '{"choices": [{"message": {"content": "mocked response"}}]}'; }
jq() {
    if [[ "$1" == "-r" ]]; then
        cat
    elif [[ "$1" == "-c" ]]; then
        echo '{"data": [{"id": "mock-model", "name": "Mock Model"}]}'
    elif [[ "$1" == "-n" ]]; then
        echo '{"test-provider": {"models": {"mock-model": {"name": "Mock Model"}}}}'
    elif [[ "$1" == "-e" ]]; then
        cat > /dev/null
        return 0
    else
        cat
    fi
}

DIR=${0:A:h}
source "${DIR}/../functions/ai.zsh" || source "${PWD}/dot_zsh/functions/ai.zsh" || source "dot_zsh/functions/ai.zsh" || exit 1

TEST_DIR=$(mktemp -d)
MARKER_FILE="$TEST_DIR/pwned"

# Reset marker
rm -f "$MARKER_FILE"

# Test 1: Valid ID
echo "--- Test 1: Valid ID ---"
ai.provider.define "test-provider" "name=Test" "openai_compatible=true"
if (( $+functions[ai.providers.test_provider.api] )); then
    echo "Function defined successfully."
    ai.providers.test_provider.api "/test/path" >/dev/null
else
    echo "Function definition failed."
    exit 1
fi

# Test 2: Malicious ID with spaces/semi-colons
echo "--- Test 2: Malicious ID ---"
ai.provider.define "malicious; touch $MARKER_FILE" "name=Malicious" "openai_compatible=true" 2>/dev/null
rc=$?
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection succeeded."
    exit 1
fi

if [[ $rc -eq 1 ]]; then
    echo "Malicious ID correctly rejected."
else
    echo "Malicious ID was not rejected by return code!"
    exit 1
fi

# Test 3: Malicious Key
echo "--- Test 3: Malicious Key ---"
rm -f "$MARKER_FILE"
ai.provider.define "test-provider2" "malicious\$(touch $MARKER_FILE)key=1" 2>/dev/null
rc=$?
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection via key succeeded."
    exit 1
fi

if [[ $rc -eq 1 ]]; then
    echo "Malicious Key correctly rejected."
else
    echo "Malicious Key was not rejected by return code!"
    exit 1
fi

# Test 4: ai.chat Malicious Provider Segment
echo "--- Test 4: ai.chat Malicious Provider ---"
rm -f "$MARKER_FILE"
ai.chat "malicious\$(touch $MARKER_FILE)/model" "hi" 2>/dev/null
rc=$?
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection via ai.chat succeeded."
    exit 1
fi

if [[ $rc -eq 1 ]]; then
    echo "Malicious ai.chat lookup correctly rejected."
else
    echo "Malicious ai.chat lookup was not rejected by return code!"
    exit 1
fi

# Test 5: Valid ai.chat
echo "--- Test 5: Valid ai.chat ---"
output=$(ai.chat "test-provider/model" "hello" <<< "hello" 2>/dev/null)
if [[ -n "$output" ]]; then
    echo "Valid ai.chat executed."
else
    echo "Valid ai.chat failed."
    exit 1
fi

# Test 6: Free Models definition check
echo "--- Test 6: Free Models Definition ---"
if (( $+functions[ai.providers.test_provider.models.free] )); then
    ai.providers.test_provider.models.free >/dev/null
else
    echo "Free models alias not defined!"
    exit 1
fi

# Test 7: Malicious models Free / lookup check
echo "--- Test 7: Malicious registry list ID filter ---"
rm -f "$MARKER_FILE"
registry.list() { echo "malicious\$(touch $MARKER_FILE)"; }
output=$(ai.models.free 2>/dev/null)
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection via ai.models.free loop succeeded."
    exit 1
else
    echo "Malicious registry lookup blocked by filter."
fi

# Test 8: Allowed special characters round-trip through the registry
echo "--- Test 8: Allowed special characters ---"
# '-' is the only non-alphanumeric character the charset permits. It is
# folded to '_' for the function name, and the registry key must agree with
# it -- otherwise the provider registers but is unreachable.
ai.provider.define "my-provider" "name=Special" "openai_compatible=true"
if (( ! $+functions[ai.providers.my_provider.api] )); then
    echo "Special character ID did not create the expected function!"
    exit 1
fi

# The registry must resolve the same id the functions were created under.
if [[ "$(registry.get ai_provider my_provider name)" != "Special" ]]; then
    echo "Registry round-trip failed: name not resolvable under the normalised id!"
    exit 1
fi

# An id that was never registered must not resolve, proving the lookup really
# depends on registry state rather than any stub answering unconditionally.
if registry.get ai_provider "never_registered" name >/dev/null 2>&1; then
    echo "Registry resolved an id that was never registered!"
    exit 1
fi

# ai.chat must accept the provider segment it just registered.
out=$(ai.chat "my-provider/any-model" "hello" 2>&1)
if [[ "$out" == *"Unknown provider"* ]]; then
    echo "ai.chat could not address the provider it just registered!"
    exit 1
fi

# '.' and ':' are not in the charset and must be rejected rather than folded.
for bad_id in "my.provider" "my:provider" "my provider"; do
    ai.provider.define "$bad_id" "name=Bad" >/dev/null 2>&1
    if (( $? == 0 )); then
        echo "Provider ID '$bad_id' was accepted but is not a supported character!"
        exit 1
    fi
done

rm -rf "$TEST_DIR"
echo "All tests passed successfully."
