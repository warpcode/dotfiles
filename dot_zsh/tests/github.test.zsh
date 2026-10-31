#!/usr/bin/env zsh

set -e

DIR=${0:A:h}
source "${DIR}/../functions/github.zsh" || source "${PWD}/dot_zsh/functions/github.zsh" || source "dot_zsh/functions/github.zsh" || exit 1

echo "Running github.zsh unit tests..."

# ---------------------------------------------------------------------------
# Test 1: _github_validate_repo validation
# ---------------------------------------------------------------------------
echo "--- Test 1: _github_validate_repo ---"
if ! _github_validate_repo "warpcode/dotfiles"; then
    echo "FAILED: valid repo failed validation"
    exit 1
fi

if ! _github_validate_repo "owner/sub.repo-1_2"; then
    echo "FAILED: valid repo with symbols failed validation"
    exit 1
fi

if _github_validate_repo "owner/repo;rm -rf /" 2>/dev/null; then
    echo "FAILED: malicious repo name succeeded validation"
    exit 1
fi
echo "PASSED: _github_validate_repo"

# ---------------------------------------------------------------------------
# Test 2: _github_flatten_subdir - single subdir with bin
# ---------------------------------------------------------------------------
echo "--- Test 2: _github_flatten_subdir with single subdir containing bin ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    mkdir -p "app-v1.0.0/bin"
    echo "binary" > "app-v1.0.0/bin/myexec"
    echo "readme" > "app-v1.0.0/README.md"
    _github_flatten_subdir
    [[ ! -d "app-v1.0.0" ]] || { echo "FAILED: app-v1.0.0 was not removed"; exit 1; }
    [[ -f "bin/myexec" ]] || { echo "FAILED: bin/myexec missing"; exit 1; }
    [[ -f "README.md" ]] || { echo "FAILED: README.md missing"; exit 1; }
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_flatten_subdir single subdir with bin"

# ---------------------------------------------------------------------------
# Test 3: _github_flatten_subdir - single subdir with lib
# ---------------------------------------------------------------------------
echo "--- Test 3: _github_flatten_subdir with single subdir containing lib ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    mkdir -p "pkg-dist/lib"
    echo "library" > "pkg-dist/lib/libtest.so"
    _github_flatten_subdir
    [[ ! -d "pkg-dist" ]] || { echo "FAILED: pkg-dist was not removed"; exit 1; }
    [[ -f "lib/libtest.so" ]] || { echo "FAILED: lib/libtest.so missing"; exit 1; }
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_flatten_subdir single subdir with lib"

# ---------------------------------------------------------------------------
# Test 4: _github_flatten_subdir - single subdir without bin or lib (untouched)
# ---------------------------------------------------------------------------
echo "--- Test 4: _github_flatten_subdir single subdir without bin or lib ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    mkdir -p "doc-folder"
    echo "docs" > "doc-folder/doc.txt"
    _github_flatten_subdir
    [[ -d "doc-folder" ]] || { echo "FAILED: doc-folder was unexpectedly removed"; exit 1; }
    [[ -f "doc-folder/doc.txt" ]] || { echo "FAILED: doc-folder/doc.txt missing"; exit 1; }
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_flatten_subdir single subdir without bin or lib"

# ---------------------------------------------------------------------------
# Test 5: _github_flatten_subdir - multiple subdirectories (untouched)
# ---------------------------------------------------------------------------
echo "--- Test 5: _github_flatten_subdir multiple subdirectories ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    mkdir -p "dir1/bin" "dir2"
    echo "bin1" > "dir1/bin/tool"
    _github_flatten_subdir
    [[ -d "dir1" && -d "dir2" ]] || { echo "FAILED: directories were altered"; exit 1; }
    [[ -f "dir1/bin/tool" ]] || { echo "FAILED: dir1/bin/tool was moved"; exit 1; }
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_flatten_subdir multiple subdirectories"

# ---------------------------------------------------------------------------
# Test 6: _github_flatten_subdir - empty directory
# ---------------------------------------------------------------------------
echo "--- Test 6: _github_flatten_subdir empty directory ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    _github_flatten_subdir
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_flatten_subdir empty directory"

# ---------------------------------------------------------------------------
# Test 7: _github_ensure_bin - creates bin and symlinks root executables
# ---------------------------------------------------------------------------
echo "--- Test 7: _github_ensure_bin creates bin and symlinks ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    echo "echo hello" > "tool"
    chmod +x "tool"
    echo "text" > "doc.txt"
    _github_ensure_bin
    [[ -d "bin" ]] || { echo "FAILED: bin directory not created"; exit 1; }
    [[ -L "bin/tool" ]] || { echo "FAILED: bin/tool symlink not created"; exit 1; }
    [[ ! -e "bin/doc.txt" ]] || { echo "FAILED: non-executable was symlinked"; exit 1; }
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_ensure_bin creates bin and symlinks"

# ---------------------------------------------------------------------------
# Test 8: _github_ensure_bin - existing non-empty bin directory preserved
# ---------------------------------------------------------------------------
echo "--- Test 8: _github_ensure_bin preserves non-empty bin ---"
TMPDIR_TEST=$(mktemp -d)
(
    cd "$TMPDIR_TEST" || exit 1
    mkdir -p "bin"
    echo "existing" > "bin/custom"
    chmod +x "bin/custom"
    echo "root tool" > "tool"
    chmod +x "tool"
    _github_ensure_bin
    [[ -f "bin/custom" && ! -L "bin/custom" ]] || { echo "FAILED: custom bin file altered"; exit 1; }
    [[ ! -e "bin/tool" ]] || { echo "FAILED: bin was populated when already non-empty"; exit 1; }
)
rm -rf "$TMPDIR_TEST"
echo "PASSED: _github_ensure_bin preserves non-empty bin"

echo "ALL GITHUB TESTS PASSED SUCCESSFULLY!"
