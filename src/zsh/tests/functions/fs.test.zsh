#!/bin/zsh

# Setup DOTFILES environment
export DOTFILES="${${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}:A:h:h:h:h:h}"
source src/zsh/init.zsh

test_fs_search_usage() {
    print "Testing fs.search usage..."
    # fs.search prints usage to stderr and returns 1 if no query is provided
    output=$(fs.search 2>&1)
    expected="Usage: fs.search [-r] [-s] <query> [dir]"
    if [[ "$output" == "$expected" ]]; then
        print "✅ Usage test passed"
    else
        print "❌ Usage test failed"
        print "Expected: $expected"
        print "Got: $output"
        return 1
    fi
}

test_fs_search_basic() {
    print "Testing fs.search basic functionality (non-git)..."
    local tmpdir=$(mktemp -d)
    (
        cd "$tmpdir"
        print "hello world" > "file1.txt"
        mkdir subdir
        print "goodbye world" > "subdir/file2.txt"

        output=$(fs.search "hello" ".")

        if [[ "$output" == *"file1.txt"* ]] && [[ "$output" == *"1:hello world"* ]]; then
            print "✅ Basic search test passed"
            return 0
        else
            print "❌ Basic search test failed"
            print "Got: $output"
            return 1
        fi
    )
    local ret=$?
    rm -rf "$tmpdir"
    return $ret
}

test_fs_search_short() {
    print "Testing fs.search -s (short mode, non-git)..."
    local tmpdir=$(mktemp -d)
    (
        cd "$tmpdir"
        print "line one" > "test.txt"
        print "line two" >> "test.txt"

        output=$(fs.search -s "line" ".")

        if [[ "$output" == *"test.txt:1:line one"* ]] && [[ "$output" == *"test.txt:2:line two"* ]]; then
            print "✅ Short mode search test passed"
            return 0
        else
            print "❌ Short mode search test failed"
            print "Got: $output"
            return 1
        fi
    )
    local ret=$?
    rm -rf "$tmpdir"
    return $ret
}

test_fs_search_regex() {
    print "Testing fs.search -r (regex mode, non-git)..."
    local tmpdir=$(mktemp -d)
    (
        cd "$tmpdir"
        print "apple" > "test.txt"
        print "banana" >> "test.txt"

        output=$(fs.search -r -s "^[ab]" ".")

        if [[ "$output" == *"apple"* ]] && [[ "$output" == *"banana"* ]]; then
            print "✅ Regex search test passed"
            return 0
        else
            print "❌ Regex search test failed"
            print "Got: $output"
            return 1
        fi
    )
    local ret=$?
    rm -rf "$tmpdir"
    return $ret
}

test_fs_search_git() {
    print "Testing fs.search in a git repository..."
    local tmpdir=$(mktemp -d)

    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test User"
        print "git content" > gitfile.txt
        git add gitfile.txt
        git commit -m "initial commit" -q

        # Run search inside the git repo
        output=$(fs.search "git content")

        if [[ "$output" == *"gitfile.txt"* ]] && [[ "$output" == *"git content"* ]]; then
            print "✅ Git search test passed"
        else
            print "❌ Git search test failed"
            print "Got: $output"
            return 1
        fi

        # Test -s in git
        output=$(fs.search -s "git content")
        if [[ "$output" == "gitfile.txt:1:git content" ]]; then
            print "✅ Git short search test passed"
        else
            print "❌ Git short search test failed"
            print "Got: $output"
            return 1
        fi
    )
    local ret=$?
    rm -rf "$tmpdir"
    return $ret
}

# Run tests
errors=0
test_fs_search_usage || errors=$((errors+1))
test_fs_search_basic || errors=$((errors+1))
test_fs_search_short || errors=$((errors+1))
test_fs_search_regex || errors=$((errors+1))
test_fs_search_git || errors=$((errors+1))

if [[ $errors -eq 0 ]]; then
    print "All tests in fs.test.zsh passed!"
    exit 0
else
    print "$errors tests failed in fs.test.zsh"
    exit 1
fi
