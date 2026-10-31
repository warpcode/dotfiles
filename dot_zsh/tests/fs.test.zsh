#!/usr/bin/env zsh

DIR=${0:A:h}
source "${DIR}/../functions/fs.zsh" || source "${PWD}/dot_zsh/functions/fs.zsh" || source "dot_zsh/functions/fs.zsh" || exit 1

# Dummy tui.heading function for non-git fs.search fallback tests
tui.heading() {
    print -- "=== $1 ==="
}

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR" || exit 1

# Setup sample directory structure
mkdir -p sub
echo "hello world" > file1.txt
echo "hello again" > sub/file2.txt
echo "goodbye" > file3.txt

echo "--- Test 1: fs.search usage check with empty query ---"
out=$(fs.search 2>&1)
rc=$?
if [[ $rc -ne 1 || "$out" != *"Usage:"* ]]; then
    echo "FAILED: Expected usage error on empty query"
    exit 1
fi
echo "PASSED"

echo "--- Test 2: fs.search in plain directory (non-git) ---"
out=$(fs.search "hello" .)
if [[ "$out" != *"file1.txt"* || "$out" != *"sub/file2.txt"* ]]; then
    echo "FAILED: Non-git search missing expected files. Output:\n$out"
    exit 1
fi
echo "PASSED"

echo "--- Test 3: fs.search with -s in plain directory (non-git) ---"
out=$(fs.search -s "hello" .)
if [[ "$out" != *"./file1.txt:1:hello world"* && "$out" != *"file1.txt:1:hello world"* ]]; then
    echo "FAILED: Non-git -s search missing expected output format. Output:\n$out"
    exit 1
fi
echo "PASSED"

echo "--- Test 4: fs.search inside git repository ---"
git init >/dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"
git add file1.txt sub/file2.txt file3.txt
git commit -m "initial commit" >/dev/null 2>&1

out=$(fs.search "hello" .)
if [[ "$out" != *"file1.txt"* || "$out" != *"sub/file2.txt"* ]]; then
    echo "FAILED: Git search missing expected files. Output:\n$out"
    exit 1
fi
echo "PASSED"

echo "--- Test 5: fs.search with -s inside git repository ---"
out=$(fs.search -s "hello" .)
if [[ "$out" != *"file1.txt:1:hello world"* || "$out" != *"sub/file2.txt:1:hello again"* ]]; then
    echo "FAILED: Git -s search missing expected simple output. Output:\n$out"
    exit 1
fi
echo "PASSED"

echo "--- Test 6: fs.search with regex (-r) option ---"
out=$(fs.search -r "hel*o" .)
if [[ "$out" != *"file1.txt"* ]]; then
    echo "FAILED: Regex search failed. Output:\n$out"
    exit 1
fi
echo "PASSED"

echo "ALL FS TESTS PASSED SUCCESSFULLY!"
