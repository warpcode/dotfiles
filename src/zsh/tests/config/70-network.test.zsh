#!/bin/zsh

# Source the file containing dataurl
source src/zsh/config/70-network.zsh

test_dataurl_usage() {
    print "Testing dataurl usage..."
    output=$(dataurl)
    exit_code=$?
    expected="Usage: dataurl <path/to/file>"
    if [[ "$output" == "$expected" ]] && [[ $exit_code -ne 0 ]]; then
        print "✅ Usage test passed"
    else
        print "❌ Usage test failed"
        print "Expected output: $expected"
        print "Got output: $output"
        print "Expected non-zero exit code, got: $exit_code"
        return 1
    fi
}

test_dataurl_missing_file() {
    print "Testing dataurl with missing file..."
    output=$(dataurl "/path/to/nonexistent/file" 2>&1)
    exit_code=$?
    expected="Error: file '/path/to/nonexistent/file' not found"
    if [[ "$output" == "$expected" ]] && [[ $exit_code -ne 0 ]]; then
        print "✅ Missing file test passed"
    else
        print "❌ Missing file test failed"
        print "Expected output: $expected"
        print "Got output: $output"
        print "Expected non-zero exit code, got: $exit_code"
        return 1
    fi
}

test_dataurl_text() {
    print "Testing dataurl with text file..."
    tmpfile=$(mktemp)
    print -n "hello world" > "$tmpfile"

    output=$(dataurl "$tmpfile")
    # openssl base64 might add a newline, and the function uses tr -d '\n' to remove it
    # "hello world" in base64 is aGVsbG8gd29ybGQ=
    expected="data:text/plain;charset=utf-8;base64,aGVsbG8gd29ybGQ="

    if [[ "$output" == "$expected" ]]; then
        print "✅ Text file test passed"
    else
        # Some versions of file might return slightly different mime types
        # or openssl might output different base64 (with/without padding)
        # Let's check if it starts with data:text/plain and contains the expected base64
        if [[ "$output" == data:text/plain* ]] && [[ "$output" == *aGVsbG8gd29ybGQ* ]]; then
             print "✅ Text file test passed (partial match)"
        else
            print "❌ Text file test failed"
            print "Expected: $expected"
            print "Got: $output"
            rm "$tmpfile"
            return 1
        fi
    fi
    rm "$tmpfile"
}

test_dataurl_binary() {
    print "Testing dataurl with binary file..."
    tmpfile=$(mktemp)
    # Create a small binary file (4 bytes of nulls)
    printf "\000\001\002\003" > "$tmpfile"

    output=$(dataurl "$tmpfile")
    # 00 01 02 03 in base64 is AAECAw==
    # MIMETYPE for binary might be application/octet-stream

    if [[ "$output" == data:*base64,AAECAw== ]]; then
        print "✅ Binary file test passed"
    else
        print "❌ Binary file test failed"
        print "Got: $output"
        rm "$tmpfile"
        return 1
    fi
    rm "$tmpfile"
}

# Run tests
errors=0
test_dataurl_usage || errors=$((errors+1))
test_dataurl_missing_file || errors=$((errors+1))
test_dataurl_text || errors=$((errors+1))
test_dataurl_binary || errors=$((errors+1))

if [[ $errors -eq 0 ]]; then
    print "All tests in 70-network.test.zsh passed!"
    exit 0
else
    print "$errors tests failed in 70-network.test.zsh"
    exit 1
fi
