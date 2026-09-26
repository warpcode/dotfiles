#!/usr/bin/env zsh

# Mock registry behavior for testing
registry.define() { return 0; }
registry.get() {
    if [[ "$2" == "malicious_echo_pwned" ]]; then
        echo "true"
    elif [[ "$3" == "openai_compatible" ]]; then
        echo "true"
    fi
}
df.cache() { return 0; }

source dot_zsh/functions/ai.zsh

_ai.provider.api_executor() { echo "api_executor $1 $2"; }
_ai.provider.models_executor() { echo "models_executor $1"; }

# Test 1: Valid ID
echo "--- Test 1: Valid ID ---"
ai.provider.define "test-provider" "name=Test" "openai_compatible=true"
if (( $+functions[ai.providers.test_provider.api] )); then
    echo "Function defined successfully."
    ai.providers.test_provider.api "/test/path"
else
    echo "Function definition failed."
fi

# Test 2: Malicious ID with spaces/semi-colons
echo "--- Test 2: Malicious ID ---"
ai.provider.define "malicious; echo pwned" "name=Malicious" "openai_compatible=true"
if [[ $? -eq 1 ]]; then
    echo "Malicious ID correctly rejected."
else
    echo "Malicious ID was not rejected!"
fi

# Test 3: Test Models Free Dispatch
echo "--- Test 3: Free Models ---"
if (( $+functions[ai.providers.test_provider.models.free] )); then
    ai.providers.test_provider.models.free
fi
