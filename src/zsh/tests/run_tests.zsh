#!/bin/zsh

# Find all .test.sh and .test.zsh files in src/zsh/tests and run them
TEST_DIR="src/zsh/tests"
total_errors=0
total_files=0

print "Running Zsh configuration tests..."
print "--------------------------------"

local test_file
# Using globbing instead of find for more idiomatic zsh
for test_file in ${TEST_DIR}/**/*.test.(sh|zsh)(N); do
    print "Running $test_file..."
    local interpreter="${test_file:e}"

    if "$interpreter" "$test_file"; then
        print "✅ $test_file passed"
    else
        print "❌ $test_file failed"
        (( total_errors++ ))
    fi
    (( total_files++ ))
done

print "--------------------------------"
if (( total_errors == 0 )); then
    print "Success: $total_files test files passed."
    exit 0
else
    print "Failure: $total_errors/$total_files test files failed."
    exit 1
fi
