#!/usr/bin/env zsh

# Mock registry behavior for testing
registry.define() { return 0; }
registry.get() {
    if [[ "$3" == "openai_compatible" ]]; then
        echo "true"
    elif [[ "$3" == "base_url" ]]; then
        echo "http://fake-base-url"
    elif [[ "$1" == "ai_provider" ]]; then
        echo "$2"
    fi
}
registry.list() { echo "test-provider"; }
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
if [[ $? -eq 1 ]]; then
    echo "Malicious ID correctly rejected."
else
    echo "Malicious ID was not rejected by return code!"
    exit 1
fi
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection succeeded."
    exit 1
fi

# Test 3: Malicious Key
echo "--- Test 3: Malicious Key ---"
rm -f "$MARKER_FILE"
ai.provider.define "test-provider2" "malicious\$(touch $MARKER_FILE)key=1" 2>/dev/null
if [[ $? -eq 1 ]]; then
    echo "Malicious Key correctly rejected."
else
    echo "Malicious Key was not rejected by return code!"
    exit 1
fi
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection via key succeeded."
    exit 1
fi

# Test 4: ai.chat Malicious Provider Segment
echo "--- Test 4: ai.chat Malicious Provider ---"
rm -f "$MARKER_FILE"
ai.chat "malicious\$(touch $MARKER_FILE)/model" "hi" 2>/dev/null
if [[ $? -eq 1 ]]; then
    echo "Malicious ai.chat lookup correctly rejected."
else
    echo "Malicious ai.chat lookup was not rejected by return code!"
    exit 1
fi
if [[ -f "$MARKER_FILE" ]]; then
    echo "MARKER FILE CREATED! Injection via ai.chat succeeded."
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

# Test 8: Allowed special characters
echo "--- Test 8: Allowed special characters ---"
ai.provider.define "my.provider:123" "name=Special" "openai_compatible=true"
if (( $+functions[ai.providers.my_provider_123.api] )); then
    echo "Special character ID definition succeeded."
else
    echo "Special character ID definition failed!"
    exit 1
fi

rm -rf "$TEST_DIR"
echo "All tests passed successfully."
