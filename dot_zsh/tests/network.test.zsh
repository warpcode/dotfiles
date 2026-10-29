#!/usr/bin/env zsh
# Unit tests for dot_zsh/config/70-network.zsh (dataurl function)

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Ensure openssl and file commands are available in PATH for minimal test environments
mkdir -p "$TMPDIR/bin"

if ! command -v openssl >/dev/null 2>&1; then
    cat >"$TMPDIR/bin/openssl" << 'EOF'
#!/bin/sh
if [ "$1" = "base64" ]; then
    shift
    while [ $# -gt 0 ]; do
        if [ "$1" = "-in" ]; then
            shift
            base64 < "$1" | tr -d "\n"
        fi
        shift
    done
fi
EOF
    chmod +x "$TMPDIR/bin/openssl"
fi

if ! command -v file >/dev/null 2>&1; then
    cat >"$TMPDIR/bin/file" << 'EOF'
#!/bin/sh
filepath=""
while [ $# -gt 0 ]; do
    filepath="$1"
    shift
done
case "$filepath" in
    *.txt) echo "text/plain" ;;
    *) echo "application/octet-stream" ;;
esac
EOF
    chmod +x "$TMPDIR/bin/file"
fi

export PATH="$TMPDIR/bin:$PATH"

source "$REPO_ROOT/config/70-network.zsh" || { print -r "Failed to source 70-network.zsh" >&2; exit 1; }

set -e

print -r "Running 70-network.zsh dataurl unit tests..."

# Test 1: Missing argument (usage)
out=""
rc=0
out=$(dataurl 2>&1) || rc=$?
if (( rc != 1 )); then
    print -r "Test 1 Failed: Expected return code 1 for missing arg, got $rc" >&2
    exit 1
fi
if [[ "$out" != *"Usage: dataurl <path/to/file>"* ]]; then
    print -r "Test 1 Failed: Expected usage output, got '$out'" >&2
    exit 1
fi

# Test 2: File not found
out=""
rc=0
out=$(dataurl "$TMPDIR/nonexistent.txt" 2>&1) || rc=$?
if (( rc != 1 )); then
    print -r "Test 2 Failed: Expected return code 1 for missing file, got $rc" >&2
    exit 1
fi
if [[ "$out" != *"Error: file '$TMPDIR/nonexistent.txt' not found"* ]]; then
    print -r "Test 2 Failed: Expected error message on stderr, got '$out'" >&2
    exit 1
fi

# Test 3: Text file
text_file="$TMPDIR/sample.txt"
print -n "hello world" > "$text_file"
out=$(dataurl "$text_file")
if [[ "$out" != "data:text/plain;charset=utf-8;base64,aGVsbG8gd29ybGQ=" ]]; then
    print -r "Test 3 Failed: Unexpected dataurl for text file, got '$out'" >&2
    exit 1
fi

# Test 4: Binary file
bin_file="$TMPDIR/sample.bin"
printf '\x00\x01\x02\x03' > "$bin_file"
out=$(dataurl "$bin_file")
if [[ "$out" != "data:application/octet-stream;base64,"* && "$out" != "data:application/x-empty;base64,"* ]]; then
    print -r "Test 4 Failed: Unexpected dataurl format for binary file, got '$out'" >&2
    exit 1
fi
if [[ "$out" == *";charset=utf-8"* ]]; then
    print -r "Test 4 Failed: Binary file should not include charset=utf-8, got '$out'" >&2
    exit 1
fi

print -r "ALL NETWORK TESTS PASSED SUCCESSFULLY!"
