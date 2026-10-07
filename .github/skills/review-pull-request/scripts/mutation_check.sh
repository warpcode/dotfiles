#!/usr/bin/env bash
# Prove a test suite actually bites, by mutating the code under test and
# recording which named tests fail.
#
# Why this exists: "all N subtests pass" is not evidence of coverage. A test
# that still passes after the branch it claims to cover is neutered is
# tautological. Proving this by hand meant re-typing the same shell function
# plus an inline `python3 - <<EOF` source rewriter on every PR -- four separate
# heredoc re-definitions of `run_mut` in a single review session, each with its
# own `cp .bak` / restore dance.
#
# Four rules this script encodes, each learned from a wrong finding:
#   1. Run the WHOLE PACKAGE, never a `-run` filter. A filtered run over the
#      PR's own table reports a gap a sibling test already closes (verified
#      2026-10-03 on warpcode/cloakenv#209: a filtered run showed double-quote
#      escaping unprotected, while `go test ./internal/engine/ -count=1` fails
#      the pre-existing TestMatchCommandRule_Security/Double_quoted_template_expansion).
#   2. Compare against the BASE branch too, to separate "this PR added an
#      untested branch" from "already untested repo-wide" (the latter is at
#      most a follow-up issue).
#   3. A mutation no test kills is a FINDING, not a pass. Report which subtest
#      caught each surviving mutation by name.
#   4. A case whose name implies a guard may actually pin a different,
#      downstream guard (verified 2026-10-03 on #209: neutering
#      isValidGroupNameOrNum left the package green because findGroupIndex
#      returning -1 shadowed it). Read the failure list before concluding.
#
# Usage:
#   mutation_check.sh --pr N --spec mutations.json --test-cmd "go test ./pkg/ -count=1" [options]
#
#   --pr N              PR number; head worktree is origin/pr-N, base is the
#                       default branch                              [required]
#   --spec FILE         JSON array of mutations (see FORMAT below) [required]
#   --test-cmd CMD      test command, run inside each worktree. Quote it.
#                                                     [required]
#   --fail-regex RE     how to recognise a failing test in the output.
#                       Defaults cover Go, pytest, unittest and cargo:
#                       ---\ FAIL|^FAIL|^\s*--- FAIL|failed|FAILED|test_.*\.\.\. FAILED
#   --skip-base         do not run the base branch (faster; loses rule 2)
#   --keep              leave the worktrees in place for manual inspection
#   --root DIR          worktree parent        [default: /tmp/opencode/wt]
#   -h, --help          show this help
#
# Mutation spec FORMAT (JSON array):
#   [{"name": "M1: drop the gStart<0 guard",
#     "path": "internal/engine/autoload.go",
#     "old":  "if gStart < 0 ||",
#     "new":  "if true ||",
#     "count": 1}]
#   "new": "" deletes the matched text. "count" defaults to 1. Use --check-like
#   precision: a pattern that does not occur verbatim is a hard error, never a
#   silent no-op, because a mutation that did not apply proves nothing.
#
# Prints a Markdown table: mutation, which subtests failed on head, whether the
# base branch was already covered, and a verdict per mutation. Then a summary:
#   SURVIVED  = no test failed -> that branch is untested (report it)
#   KILLED    = named tests failed on head but not on base -> this PR's gap
#   PRE-EXISTING = base failed too -> repo-wide gap, follow-up at most
#
# Exit codes:
#   0  every mutation was killed on head
#   1  at least one mutation survived (findings to report)
#   2  usage error, or the spec/test command was unusable

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE="$SCRIPT_DIR/review_worktree.sh"
APPLY="$SCRIPT_DIR/apply_mutation.py"

die() { printf 'mutation_check: %s\n' "$*" >&2; exit 2; }

pr=""; spec=""; test_cmd=""; fail_regex=""
skip_base=0; keep=0; root="/tmp/opencode/wt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)        pr="${2:-}"; shift 2 ;;
    --spec)      spec="${2:-}"; shift 2 ;;
    --test-cmd)  test_cmd="${2:-}"; shift 2 ;;
    --fail-regex) fail_regex="${2:-}"; shift 2 ;;
    --root)      root="${2:-}"; shift 2 ;;
    --skip-base) skip_base=1; shift ;;
    --keep)      keep=1; shift ;;
    -h|--help)   sed -n '2,60p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           die "unknown argument: $1" ;;
  esac
done

[[ -n "$pr"       ]] || die "--pr is required"
[[ -n "$spec"     ]] || die "--spec is required"
[[ -n "$test_cmd" ]] || die "--test-cmd is required"
[[ -f "$spec"   ]] || die "spec file not found: $spec"
[[ -f "$APPLY"  ]] || die "missing $APPLY"
[[ -f "$WORKTREE" ]] || die "missing $WORKTREE"
command -v jq >/dev/null 2>&1 || die "jq is required"

# Default: the shapes of a failing test name across the common runners.
[[ -n "$fail_regex" ]] || fail_regex='^\s*--- FAIL|^--- FAIL|^FAIL|^ok .*FAIL|FAILED|failed|panicked'

total="$(jq 'length' "$spec")"
[[ "$total" -gt 0 ]] || die "spec contains no mutations"

cleanup() {
  if [[ "$keep" -eq 1 ]]; then
    printf 'mutation_check: --keep, worktrees left under %s (pr%s-head, pr%s-base)\n' \
      "$root" "$pr" "$pr" >&2
  else
    bash "$WORKTREE" rm --pr "$pr" --all-roles --root "$root" --force >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Create both worktrees up front so a missing ref fails before any work.
head_wt="$(bash "$WORKTREE" add --pr "$pr" --role head --root "$root")"
base_wt=""
if [[ "$skip_base" -eq 0 ]]; then
  base_wt="$(bash "$WORKTREE" add --pr "$pr" --role base --root "$root")"
fi

# Extract the names of failing tests from a test run's combined output.
#
# The name is what a finding must quote, so it is normalised to a bare
# identifier: Go's `--- FAIL: TestFoo (0.00s)` becomes `TestFoo`, and a
# subtest's `    --- FAIL: TestFoo/case` becomes `TestFoo/case`. Package-level
# summary lines (`FAIL\texample.com/pkg\t0.002s`) and bare `FAIL` are dropped:
# they name no test and would otherwise pad the report with noise.
failing_tests() {
  local log="$1"
  [[ -f "$log" ]] || return 0

  local names
  # Preferred source: an explicit per-test FAIL line.
  names="$(sed -nE 's/^[[:space:]]*---[[:space:]]+FAIL:[[:space:]]+([^[:space:]]+).*/\1/p' "$log" | sort -u)"
  if [[ -z "$names" ]]; then
    # Fallback for other runners: pytest `FAILED path::test - ...`,
    # cargo `test foo ... FAILED`, TAP `not ok N - name`.
    names="$(grep -E "$fail_regex" "$log" 2>/dev/null \
      | sed -E 's/^[[:space:]]*(FAIL|Failed|FAILED|failed|not ok)[[:space:]:]+//;
               s/^[[:space:]]*[-=*]+[[:space:]]*//;
               s/^test[[:space:]]+//;
               s/[[:space:]]+[-=].*$//;
               s/[[:space:]]*\(.*\)$//;
               s/[[:space:]]+\.\.\..*$//;
               s/[[:space:]]+$//' \
      | grep -vE '^(FAIL|ok|ok |---|\[|Compiling|error|Error|panic|cannot|no test)' \
      | grep -vE '^[0-9]+ (failed|passed|error)' \
      | grep -vE '^(test result:|[0-9]+ (passed|failed)|FAILED |short test summary)' \
      | grep -vE '^[[:space:]]*$' \
      | sort -u || true)"
  fi
  printf '%s\n' "$names" | grep -vE '^[[:space:]]*$' | head -10 || true
}

# run_tests <worktree> <label> -> writes output to $LOGDIR/<label>.log
LOGDIR="$(mktemp -d)"
run_tests() {
  local wt="$1"
  local label="$2"
  local log="$LOGDIR/${label}.log"
  : > "$log"
  if ( cd "$wt" && eval "$test_cmd" ) >"$log" 2>&1; then
    return 0
  fi
  return 1
}

# apply_mutation <worktree> <index> -> 0 applied, non-zero not applied
apply_one() {
  local wt="$1" idx="$2" tmp
  tmp="$(mktemp)"
  jq ".[$idx]" "$spec" > "$tmp"
  python3 "$APPLY" "$tmp" --root "$wt" >/dev/null 2>&1
  local rc=$?
  rm -f "$tmp"
  return $rc
}

printf 'mutation_check: pr #%s, %s mutation(s), worktrees %s%s\n' \
  "$pr" "$total" "$head_wt" "${base_wt:+ and $base_wt}" >&2

survived=0
killed=0
preexisting=0
notapplied=0
results="$(mktemp)"

for i in $(seq 0 $((total - 1))); do
  name="$(jq -r ".[$i].name // \"mutation $i\"" "$spec")"
  rel_path="$(jq -r ".[$i].path" "$spec")"

  # --- head -------------------------------------------------------------------
  head_file="$head_wt/$rel_path"
  [[ -f "$head_file" ]] || { printf 'SKIP  %s (no such file: %s)\n' "$name" "$rel_path" >&2; notapplied=$((notapplied+1)); continue; }
  cp "$head_file" "$LOGDIR/orig.head"

  if ! apply_one "$head_wt" "$i"; then
    cp "$LOGDIR/orig.head" "$head_file"
    printf 'ERROR %s (pattern did not apply in %s -- a mutation that did not apply proves nothing)\n' \
      "$name" "$rel_path" >&2
    notapplied=$((notapplied+1))
    continue
  fi

  if run_tests "$head_wt" "head-$i"; then head_killed=0; else head_killed=1; fi
  head_tests="$(failing_tests "$LOGDIR/head-$i.log" | tr '\n' ';' | sed 's/;$//')"
  cp "$LOGDIR/orig.head" "$head_file"          # restore, unconditionally

  # --- base (rule 2) ----------------------------------------------------------
  base_killed=""
  if [[ -n "$base_wt" ]]; then
    base_file="$base_wt/$rel_path"
    if [[ -f "$base_file" ]]; then
      cp "$base_file" "$LOGDIR/orig.base"
      if apply_one "$base_wt" "$i"; then
        if run_tests "$base_wt" "base-$i"; then base_killed=0; else base_killed=1; fi
        cp "$LOGDIR/orig.base" "$base_file"
      else
        base_killed="n/a"   # the guard may not exist on base at all
      fi
    else
      base_killed="n/a"
    fi
  fi

  if [[ "$head_killed" -eq 0 ]]; then
    verdict="SURVIVED"
    survived=$((survived+1))
  elif [[ "$base_killed" == "1" ]]; then
    verdict="PRE-EXISTING"
    preexisting=$((preexisting+1))
  elif [[ "$base_killed" == "n/a" ]]; then
    verdict="KILLED"
    killed=$((killed+1))
  else
    verdict="KILLED"
    killed=$((killed+1))
  fi

  jq -n \
    --arg name "$name" \
    --arg path "$rel_path" \
    --arg verdict "$verdict" \
    --arg tests "${head_tests:-none}" \
    '{name: $name, path: $path, verdict: $verdict, tests: $tests}' >> "$results"
done

# --- report -------------------------------------------------------------------
echo
echo "| mutation | file | verdict | failing test(s) on head |"
echo "| --- | --- | --- | --- |"
jq -r '"| \(.name) | `\(.path)` | **\(.verdict)** | \(.tests) |"' "$results"

echo
echo "killed=$killed survived=$survived pre-existing=$preexisting not-applied=$notapplied"
echo "logs: $LOGDIR"

rm -f "$results"

if [[ "$notapplied" -gt 0 ]]; then
  printf 'mutation_check: %s mutation(s) never applied -- fix the spec patterns; do not report them as gaps\n' \
    "$notapplied" >&2
  exit 2
fi
if [[ "$survived" -gt 0 ]]; then
  printf 'mutation_check: %s mutation(s) survived -- those branches are untested\n' "$survived" >&2
  exit 1
fi
printf 'mutation_check: every mutation was killed by at least one named test\n' >&2