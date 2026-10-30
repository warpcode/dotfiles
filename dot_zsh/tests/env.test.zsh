#!/usr/bin/env zsh
# Unit tests for dot_zsh/functions/env.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

source "$REPO_ROOT/functions/env.zsh" || { print -r "Failed to source env.zsh" >&2; exit 1; }

set -e

print -r "Running env.zsh unit tests..."

# Test 1: env.lazy.register & env.lazy.load
env.lazy.register "TEST_VAR_A" "echo hello_a"
if [[ "${_ENV_LAZY_VARS[TEST_VAR_A]}" != "echo hello_a" ]]; then
    print -r "Test 1 Failed: registration failed" >&2
    exit 1
fi

env.lazy.load "TEST_VAR_A"
if [[ "$TEST_VAR_A" != "hello_a" ]]; then
    print -r "Test 1 Failed: env.lazy.load did not set TEST_VAR_A correctly, got '$TEST_VAR_A'" >&2
    exit 1
fi

# Test 2: Invalid variable name rejection
if env.lazy.register "123_INVALID" "echo bad" 2>/dev/null; then
    print -r "Test 2 Failed: env.lazy.register accepted invalid var name" >&2
    exit 1
fi

# Test 3: Lazy load dependencies
env.lazy.register "TEST_VAR_DEP" "echo loaded_dep"
env.lazy.register "TEST_VAR_MAIN" 'echo "main_${TEST_VAR_DEP}"' "TEST_VAR_DEP"

env.lazy.load "TEST_VAR_MAIN"
if [[ "$TEST_VAR_DEP" != "loaded_dep" ]]; then
    print -r "Test 3 Failed: dependency TEST_VAR_DEP was not loaded" >&2
    exit 1
fi
if [[ "$TEST_VAR_MAIN" != "main_loaded_dep" ]]; then
    print -r "Test 3 Failed: TEST_VAR_MAIN did not evaluate correctly with dependency, got '$TEST_VAR_MAIN'" >&2
    exit 1
fi

# Test 4: env.lazy.reset
env.lazy.reset "TEST_VAR_A"
if [[ -v TEST_VAR_A ]]; then
    print -r "Test 4 Failed: env.lazy.reset did not unset TEST_VAR_A" >&2
    exit 1
fi

# Test 5: env.lazy.load_all
env.lazy.reset "TEST_VAR_DEP" "TEST_VAR_MAIN"
env.lazy.load_all
if [[ "$TEST_VAR_A" != "hello_a" || "$TEST_VAR_MAIN" != "main_loaded_dep" ]]; then
    print -r "Test 5 Failed: env.lazy.load_all failed" >&2
    exit 1
fi

# Test 6: env.print.kv & env.print.var
kv_out="$(env.print.kv MYVAR myvalue)"
if [[ "$kv_out" != "MYVAR=myvalue" ]]; then
    print -r "Test 6 Failed: env.print.kv output incorrect, got '$kv_out'" >&2
    exit 1
fi

print -r "ALL ENV TESTS PASSED SUCCESSFULLY!"
