#!/usr/bin/env zsh

DIR=${0:A:h}
source "${DIR}/../functions/tui.zsh" || return 1

TEST_DIR=$(mktemp -d)
MARKER_FILE="$TEST_DIR/pwned"
rm -f "$MARKER_FILE"

# Test 1: tui.indent.push
tui.indent.push 'a[0$(touch '"$MARKER_FILE"')]' 2>/dev/null
if [[ -f "$MARKER_FILE" ]]; then
    echo "tui.indent.push injection succeeded!"
    return 1
fi

# Test 2: tui.indent.pop
tui.indent.pop 'a[0$(touch '"$MARKER_FILE"')]' 2>/dev/null
if [[ -f "$MARKER_FILE" ]]; then
    echo "tui.indent.pop injection succeeded!"
    return 1
fi

# Test 3: tui.with_indent
tui.with_indent 'a[0$(touch '"$MARKER_FILE"')]' echo foo >/dev/null 2>/dev/null
if [[ -f "$MARKER_FILE" ]]; then
    echo "tui.with_indent injection succeeded!"
    return 1
fi

# Test 4: valid tui.with_indent
out=$(tui.with_indent '1' echo foo 2>/dev/null)
if [[ "$out" != "foo" ]]; then
    echo "tui.with_indent broke for valid input!"
    return 1
fi

rm -rf "$TEST_DIR"
echo "All tests passed successfully."
