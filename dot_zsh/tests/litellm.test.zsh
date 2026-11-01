#!/usr/bin/env zsh

set -e

DIR=${0:A:h}
source "${DIR}/../apps/ai/litellm.zsh" || source "${PWD}/dot_zsh/apps/ai/litellm.zsh" || exit 1

echo "Running litellm.zsh unit tests..."

# Test 1: No arguments prints usage and returns 1
echo "--- Test 1: No arguments ---"
err_msg=$(ai.litellm.proxy.wrapper 2>&1 || true)
if [[ "$err_msg" != *"Usage: ai.litellm.proxy.wrapper"* ]]; then
    echo "Expected usage error message, got: $err_msg"
    exit 1
fi

# Test 2: Bypass when LiteLLM is already running on port 4000
echo "--- Test 2: Server already running ---"
curl() {
    return 0
}
marker_file=$(mktemp)
rm -f "$marker_file"
dummy_cmd() {
    touch "$marker_file"
    return 0
}
out=$(ai.litellm.proxy.wrapper dummy_cmd 2>&1)
if [[ ! -f "$marker_file" ]] || [[ "$out" != *"already running on port 4000"* ]]; then
    echo "Failed bypass check: out=$out"
    rm -f "$marker_file"
    exit 1
fi
rm -f "$marker_file"
unset -f curl
unset -f dummy_cmd

# Test 3: Failed config generation returns 1
echo "--- Test 3: Failed config generation ---"
curl() {
    return 1
}
ai.litellm.config.from.openrouter.free() {
    return 1
}
err_msg=$(ai.litellm.proxy.wrapper true 2>&1 || true)
if [[ "$err_msg" != *"Failed to generate LiteLLM config"* ]]; then
    echo "Expected config error message, got: $err_msg"
    exit 1
fi
unset -f ai.litellm.config.from.openrouter.free

# Test 4: Startup failure (process dies during wait)
echo "--- Test 4: Startup failure (process dies) ---"
tmp_cfg=$(mktemp)
ai.litellm.config.from.openrouter.free() {
    echo "$tmp_cfg"
}
env.lazy.load() { :; }
uvx() {
    # Fake command that terminates immediately
    sh -c 'exit 1'
}
pkill() { :; }
err_msg=$(ai.litellm.proxy.wrapper true 2>&1 || true)
if [[ "$err_msg" != *"LiteLLM failed to start"* ]]; then
    echo "Expected startup failure message, got: $err_msg"
    exit 1
fi
if [[ -f "$tmp_cfg" ]]; then
    echo "Config file was not cleaned up!"
    rm -f "$tmp_cfg"
    exit 1
fi

# Test 5: Timeout waiting for server readiness
echo "--- Test 5: Timeout waiting for readiness ---"
tmp_cfg=$(mktemp)
ai.litellm.config.from.openrouter.free() {
    echo "$tmp_cfg"
}
uvx() {
    exec sleep 10
}
uvx >/dev/null 2>&1 &
fake_pid=$!

_ai.litellm.is_ready() { return 1; }

err_msg=$(_ai.litellm.wait_ready 4000 "$fake_pid" 0 2>&1 || true)
kill "$fake_pid" 2>/dev/null || true
wait "$fake_pid" 2>/dev/null || true
rm -f "$tmp_cfg"

if [[ "$err_msg" != *"failed to start within 0s"* ]]; then
    echo "Expected timeout message, got: $err_msg"
    exit 1
fi

# Test 6: Successful startup, command execution, and cleanup
echo "--- Test 6: Successful startup and cleanup ---"
tmp_cfg=$(mktemp)
ai.litellm.config.from.openrouter.free() {
    echo "$tmp_cfg"
}
uvx() {
    exec sleep 10
}
_ai.litellm.wait_ready() { return 0; }
env.lazy.load() { :; }
marker_file=$(mktemp)
rm -f "$marker_file"
dummy_run() {
    touch "$marker_file"
    return 0
}

out=$(ai.litellm.proxy.wrapper dummy_run 2>&1)
if [[ ! -f "$marker_file" ]]; then
    echo "Dummy run command did not execute!"
    exit 1
fi
rm -f "$marker_file"

if [[ "$out" != *"LiteLLM ready. Running: dummy_run"* ]]; then
    echo "Expected ready message, got: $out"
    exit 1
fi

if [[ -f "$tmp_cfg" ]]; then
    echo "Config file was not cleaned up!"
    rm -f "$tmp_cfg"
    exit 1
fi

echo "ALL LITELLM TESTS PASSED SUCCESSFULLY!"
