#!/usr/bin/env zsh

emulate -LR zsh
setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL

DIR=${0:A:h}
DF_CACHE_BIN="${DIR}/../../dot_local/bin/executable_df.cache"

TEST_DIR=$(mktemp -d)

# Do not exit early during trap setup
trap 'rm -rf "$TEST_DIR"' EXIT

echo "--- Test 1: Stats on empty directory ---"
out=$(DF_CACHE_DIR="$TEST_DIR" zsh "${DF_CACHE_BIN}" stats)
if [[ "$out" != *"Total entries: 0"* ]]; then
  echo "FAILED: Expected Total entries: 0. Got:\n$out"
  return 1
fi
echo "PASSED"

echo "--- Test 2: Prune on empty directory ---"
DF_CACHE_DIR="$TEST_DIR" zsh "${DF_CACHE_BIN}" prune
echo "PASSED"

echo "--- Test 3: Setup test data ---"
mkdir -p "${TEST_DIR}/ns1"
echo "val1" > "${TEST_DIR}/ns1/1.cache"
sleep 2
echo "val2" > "${TEST_DIR}/ns1/2.cache"
echo "PASSED"

echo "--- Test 4: Stats with data ---"
out=$(DF_CACHE_DIR="$TEST_DIR" zsh "${DF_CACHE_BIN}" stats 1)
if [[ "$out" != *"Total entries: 2"* || "$out" != *"Expired entries: 1"* ]]; then
  echo "FAILED: Stats logic mismatch. Got:\n$out"
  return 1
fi
echo "PASSED"

echo "--- Test 5: Prune with data ---"
DF_CACHE_DIR="$TEST_DIR" zsh "${DF_CACHE_BIN}" prune 1
out=$(DF_CACHE_DIR="$TEST_DIR" zsh "${DF_CACHE_BIN}" stats 1)
if [[ "$out" != *"Total entries: 1"* || "$out" != *"Expired entries: 0"* ]]; then
  echo "FAILED: Prune logic mismatch. Got:\n$out"
  return 1
fi
echo "PASSED"

echo "ALL DF CACHE TESTS PASSED SUCCESSFULLY!"
