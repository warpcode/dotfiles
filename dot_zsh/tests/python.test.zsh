#!/usr/bin/env zsh

DIR=${0:A:h}
export _W_PYTHON_COMMAND="python3"
source "${DIR}/../apps/python.zsh" || exit 1

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

DEACTIVATED=0
deactivate() {
    DEACTIVATED=1
    unset VIRTUAL_ENV
}

# Test 1: Active venv matches requested venvpath
echo "--- Test 1: Already active venv ---"
export VIRTUAL_ENV="/path/to/myvenv"
DEACTIVATED=0
python.vrun "/path/to/myvenv"
rc=$?
if [[ $rc -ne 0 ]]; then
    echo "Expected return code 0, got $rc"
    exit 1
fi
if [[ $DEACTIVATED -ne 0 ]]; then
    echo "deactivate was called unexpectedly"
    exit 1
fi
echo "Pass: Early return when venv already active."

# Test 2: Active venv differs from requested venvpath
echo "--- Test 2: Deactivating different active venv ---"
export VIRTUAL_ENV="/path/to/oldvenv"
DEACTIVATED=0
python.vrun "$TEST_DIR/nonexistent_venv" 2>/dev/null
rc=$?
if [[ $rc -ne 1 ]]; then
    echo "Expected return code 1 for non-existent venv, got $rc"
    exit 1
fi
if [[ $DEACTIVATED -ne 1 ]]; then
    echo "deactivate was not called"
    exit 1
fi
echo "Pass: Deactivated old venv before checking new venv."

# Test 3: Non-existent venv path
echo "--- Test 3: Non-existent venv ---"
unset VIRTUAL_ENV
python.vrun "$TEST_DIR/nonexistent_venv"
rc=$?
if [[ $rc -ne 1 ]]; then
    echo "Expected return code 1, got $rc"
    exit 1
fi
echo "Pass: Returned 1 for non-existent venv path."

# Test 4: Invalid venv structure (directory without bin/activate)
echo "--- Test 4: Invalid venv structure ---"
mkdir -p "$TEST_DIR/invalid_venv"
unset VIRTUAL_ENV
stderr_out=$(python.vrun "$TEST_DIR/invalid_venv" 2>&1)
rc=$?
if [[ $rc -ne 1 ]]; then
    echo "Expected return code 1, got $rc"
    exit 1
fi
if [[ "$stderr_out" != *"is not a proper virtual environment"* ]]; then
    echo "Expected error message in stderr, got: $stderr_out"
    exit 1
fi
echo "Pass: Correctly identified improper venv."

# Test 5: Successful activation
echo "--- Test 5: Successful venv activation ---"
mkdir -p "$TEST_DIR/valid_venv/bin"
cat << 'EOF' > "$TEST_DIR/valid_venv/bin/activate"
export VIRTUAL_ENV="valid_venv_active"
EOF
unset VIRTUAL_ENV
python.vrun "$TEST_DIR/valid_venv" > "$TEST_DIR/activation.log"
rc=$?
if [[ $rc -ne 0 ]]; then
    echo "Expected return code 0, got $rc"
    exit 1
fi
if [[ "$VIRTUAL_ENV" != "valid_venv_active" ]]; then
    echo "Failed to activate venv, VIRTUAL_ENV=$VIRTUAL_ENV"
    exit 1
fi
stdout_out=$(cat "$TEST_DIR/activation.log")
if [[ "$stdout_out" != *"Activated virtual environment valid_venv_active"* ]]; then
    echo "Expected activation message in stdout, got: $stdout_out"
    exit 1
fi
echo "Pass: Successfully activated virtual environment."

echo "All python.zsh tests passed successfully."
