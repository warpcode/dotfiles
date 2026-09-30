#!/usr/bin/env zsh
# Unit tests for dot_zsh/functions/registry.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

source "$REPO_ROOT/functions/registry.zsh" || { print -r "Failed to source registry.zsh" >&2; exit 1; }

set -e

print -r "Running registry.zsh unit tests..."

# Test 1: Define and get standard key-value pairs
registry.define test_app provider1 name="Ollama" endpoint="http://localhost:11434"
if [[ "$(registry.get test_app provider1 name)" != "Ollama" ]]; then
    print -r "Test 1 Failed: name is not Ollama" >&2
    exit 1
fi
if [[ "$(registry.get test_app provider1 endpoint)" != "http://localhost:11434" ]]; then
    print -r "Test 1 Failed: endpoint incorrect" >&2
    exit 1
fi

# Test 2: List and exists
if ! registry.exists test_app provider1; then
    print -r "Test 2 Failed: provider1 should exist" >&2
    exit 1
fi
if [[ "$(registry.list test_app)" != "provider1" ]]; then
    print -r "Test 2 Failed: list output incorrect" >&2
    exit 1
fi

# Test 3: Security test with shell metacharacters and single/double quotes
# Unsafe eval previously would execute commands or fail on quotes
malicious_val='"; echo "HACKED"; $(whoami); `'
registry.define test_app provider2 secret="$malicious_val" note='single '\'' quote and $VAR'

if [[ "$(registry.get test_app provider2 secret)" != "$malicious_val" ]]; then
    print -r "Test 3 Failed: secret value modified or mis-handled" >&2
    exit 1
fi

if [[ "$(registry.get test_app provider2 note)" != 'single '\'' quote and $VAR' ]]; then
    print -r "Test 3 Failed: single quote value mis-handled" >&2
    exit 1
fi

# Test 4: Duplicate defines update values without duplicating in list
registry.define test_app provider1 name="Ollama Updated"
list_count=$(registry.list test_app | wc -l | tr -d ' ')
if [[ "$list_count" != "2" ]]; then
    print -r "Test 4 Failed: provider count in list should be 2, got $list_count" >&2
    exit 1
fi
if [[ "$(registry.get test_app provider1 name)" != "Ollama Updated" ]]; then
    print -r "Test 4 Failed: provider1 name not updated" >&2
    exit 1
fi

print -r "ALL REGISTRY TESTS PASSED SUCCESSFULLY!"
