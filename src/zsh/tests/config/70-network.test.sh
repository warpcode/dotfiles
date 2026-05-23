#!/bin/bash

# Source the file containing dataurl
# Since it's a zsh file, we hope it's compatible enough with bash for this function
source src/zsh/config/70-network.zsh

test_dataurl_usage() {
    echo "Testing dataurl usage..."
    output=$(dataurl)
    exit_code=$?
    expected="Usage: dataurl <path/to/file>"
    if [ "$output" == "$expected" ] && [ $exit_code -ne 0 ]; then
        echo "✅ Usage test passed"
    else
        echo "❌ Usage test failed"
        echo "Expected output: $expected"
        echo "Got output: $output"
        echo "Expected non-zero exit code, got: $exit_code"
        return 1
    fi
}

test_dataurl_text() {
    echo "Testing dataurl with text file..."
    tmpfile=$(mktemp)
    echo -n "hello world" > "$tmpfile"

    output=$(dataurl "$tmpfile")
    # openssl base64 might add a newline, and the function uses tr -d '\n' to remove it
    # "hello world" in base64 is aGVsbG8gd29ybGQ=
    expected="data:text/plain;charset=utf-8;base64,aGVsbG8gd29ybGQ="

    if [ "$output" == "$expected" ]; then
        echo "✅ Text file test passed"
    else
        # Some versions of file might return slightly different mime types
        # or openssl might output different base64 (with/without padding)
        # Let's check if it starts with data:text/plain and contains the expected base64
        if [[ "$output" == data:text/plain* ]] && [[ "$output" == *aGVsbG8gd29ybGQ* ]]; then
             echo "✅ Text file test passed (partial match)"
        else
            echo "❌ Text file test failed"
            echo "Expected: $expected"
            echo "Got: $output"
            rm "$tmpfile"
            return 1
        fi
    fi
    rm "$tmpfile"
}

test_dataurl_binary() {
    echo "Testing dataurl with binary file..."
    tmpfile=$(mktemp)
    # Create a small binary file (4 bytes of nulls)
    printf "\000\001\002\003" > "$tmpfile"

    output=$(dataurl "$tmpfile")
    # 00 01 02 03 in base64 is AAECAw==
    # MIMETYPE for binary might be application/octet-stream

    if [[ "$output" == data:*base64,AAECAw== ]]; then
        echo "✅ Binary file test passed"
    else
        echo "❌ Binary file test failed"
        echo "Got: $output"
        rm "$tmpfile"
        return 1
    fi
    rm "$tmpfile"
}

# Run tests
errors=0
test_dataurl_usage || errors=$((errors+1))
test_dataurl_text || errors=$((errors+1))
test_dataurl_binary || errors=$((errors+1))

if [ $errors -eq 0 ]; then
    echo "All tests in 70-network.test.sh passed!"
    exit 0
else
    echo "$errors tests failed in 70-network.test.sh"
    exit 1
fi
