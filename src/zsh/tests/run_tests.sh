#!/bin/bash

# Find all .test.sh files in src/zsh/tests and run them
TEST_DIR="src/zsh/tests"
total_errors=0
total_files=0

echo "Running Zsh configuration tests..."
echo "--------------------------------"

while IFS= read -r test_file; do
    echo "Running $test_file..."
    interpreter="bash"
    [[ "$test_file" == *.zsh ]] && interpreter="zsh"

    if "$interpreter" "$test_file"; then
        echo "✅ $test_file passed"
    else
        echo "❌ $test_file failed"
        total_errors=$((total_errors + 1))
    fi
    total_files=$((total_files + 1))
done < <(find "$TEST_DIR" -name "*.test.sh" -o -name "*.test.zsh")

echo "--------------------------------"
if [ $total_errors -eq 0 ]; then
    echo "Success: $total_files test files passed."
    exit 0
else
    echo "Failure: $total_errors/$total_files test files failed."
    exit 1
fi
