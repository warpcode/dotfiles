#!/usr/bin/env zsh

DIR=${0:A:h}
source "${DIR}/../functions/env.zsh" || source "${PWD}/dot_zsh/functions/env.zsh" || source "dot_zsh/functions/env.zsh" || exit 1

echo "--- Test 1: env.lazy.register validation ---"
if env.lazy.register "123_INVALID" "echo bad" 2>/dev/null; then
  echo "FAILED: Expected registration of invalid variable name to fail"
  exit 1
fi
echo "PASSED"

echo "--- Test 2: env.lazy.register and load ---"
env.lazy.register TEST_LAZY_VAR "echo hello_world"
env.lazy.load TEST_LAZY_VAR
if [[ "$TEST_LAZY_VAR" != "hello_world" ]]; then
  echo "FAILED: TEST_LAZY_VAR is '$TEST_LAZY_VAR', expected 'hello_world'"
  exit 1
fi
echo "PASSED"

echo "--- Test 3: env.lazy.load with dependencies and seen tracking ---"
env.lazy.register TEST_DEP_A "echo part_a"
env.lazy.register TEST_DEP_B "echo part_b_\$TEST_DEP_A" TEST_DEP_A
env.lazy.register TEST_DEP_MAIN "echo \$TEST_DEP_A-\$TEST_DEP_B" TEST_DEP_A TEST_DEP_B
env.lazy.load TEST_DEP_MAIN
if [[ "$TEST_DEP_A" != "part_a" || "$TEST_DEP_B" != "part_b_part_a" || "$TEST_DEP_MAIN" != "part_a-part_b_part_a" ]]; then
  echo "FAILED: Dependency loading mismatch"
  exit 1
fi
echo "PASSED"

echo "--- Test 4: env.lazy.reset ---"
env.lazy.reset TEST_LAZY_VAR
if [[ -v TEST_LAZY_VAR ]]; then
  echo "FAILED: TEST_LAZY_VAR was not unset after reset"
  exit 1
fi
echo "PASSED"

echo "--- Test 5: env.get ---"
val=$(env.get TEST_DEP_MAIN)
if [[ "$val" != "part_a-part_b_part_a" ]]; then
  echo "FAILED: env.get returned '$val'"
  exit 1
fi
echo "PASSED"

echo "--- Test 6: env.print.kv and env.print.var ---"
out=$(env.print.var TEST_DEP_MAIN)
if [[ "$out" != "TEST_DEP_MAIN=part_a-part_b_part_a" ]]; then
  echo "FAILED: env.print.var returned '$out'"
  exit 1
fi
echo "PASSED"

echo "ALL ENV TESTS PASSED SUCCESSFULLY!"
