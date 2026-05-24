#!/bin/zsh
# env_expansion.zsh - Test suite for Zsh dynamic backreference expansion
# This verifies the logic used in env.lazy.load to expand variables safely.

setopt EXTENDED_GLOB

expand_test() {
  local p=$1
  local expected=$2
  local result
  
  # Logic from env.zsh:
  # 1. (Q) removes one level of quoting
  # 2. //(#b) performs global substitution with backreferences
  # 3. (P) evaluates the captured variable name dynamically
  result="${(Q)p//(#b)\$(([a-zA-Z_][a-zA-Z0-9_]#)|\{([a-zA-Z_][a-zA-Z0-9_]#)\})/${(P)match[2]:-${(P)match[3]}}}"
  
  if [[ "$result" == "$expected" ]]; then
    print -P "%F{green}PASS%f: '$p' -> '$result'"
  else
    print -P "%F{red}FAIL%f: '$p' -> '$result' (Expected: '$expected')"
    return 1
  fi
}

# Test Data
export TEST_VAR="success"
export HOME_DIR="/home/user"
export APP_PORT="8080"

print "Starting Zsh expansion tests..."
expand_test '$TEST_VAR' "success"
expand_test '${TEST_VAR}' "success"
expand_test '"$TEST_VAR"' "success"
expand_test "'\$TEST_VAR'" "success" # Note: simplifies to expansion even in single quotes (known limitation)
expand_test '$HOME_DIR/app' "/home/user/app"
expand_test 'localhost:$APP_PORT' "localhost:8080"
expand_test '${HOME_DIR}_backup' "/home/user_backup"

print "\nAll tests completed."
