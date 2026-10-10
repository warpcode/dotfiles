#!/usr/bin/env bash
# bench_compare.sh: Compare Go benchmarks across two git refs, handling benchmarks
# that exist on only one side.
#
# A PR frequently ADDS benchmark files. Copying those files into the base tree is
# what makes a like-for-like comparison possible; without it you end up quoting
# figures for a benchmark that never existed on base, or skipping the one case
# that actually justifies the change.
#
# Usage:
#   bench_compare.sh <base-ref> <head-ref> [options]
#
# Options:
#   --bench <regex>   Benchmark name filter (default: matches all benchmarks)
#   --pkg <path>      Package path to test (default: ./...)
#   --count <n>       Repeat count passed to -count (default: 3)
#   --json            Emit JSON instead of a Markdown table
#   --keep            Do not remove the temporary worktrees on exit
#   -h, --help        Show this help
#
# Examples:
#   bench_compare.sh origin/main origin/tidy/pr-214-uri-expand-perf \
#       --bench 'BenchmarkParseURI|BenchmarkExpandString' --pkg ./internal/utils/
#   bench_compare.sh main HEAD --pkg ./internal/engine/
#
# Exit codes:
#   0  comparison completed
#   1  usage error, or a benchmark run failed
#
# Notes:
#   - Requires a git worktree-capable repo and the `go` toolchain on both trees.
#   - Benchmark numbers are machine-specific. Always paste the table this script
#     produces into the PR body; never transcribe figures from a previous run.

set -euo pipefail

SCRIPT_NAME=$(basename "$0")

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'
  exit "${1:-0}"
}

die() {
  echo "${SCRIPT_NAME}: $*" >&2
  exit 1
}

[ $# -ge 2 ] || usage 1

BASE_REF=$1
HEAD_REF=$2
shift 2

BENCH_RE='.'
PKG='./...'
COUNT=3
AS_JSON=false
KEEP=false

while [ $# -gt 0 ]; do
  case "$1" in
    --bench) [ $# -ge 2 ] || die "--bench requires a value"; BENCH_RE=$2; shift 2 ;;
    --pkg)   [ $# -ge 2 ] || die "--pkg requires a value";   PKG=$2;   shift 2 ;;
    --count) [ $# -ge 2 ] || die "--count requires a value"; COUNT=$2; shift 2 ;;
    --json)  AS_JSON=true; shift ;;
    --keep)  KEEP=true; shift ;;
    -h|--help) usage 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

command -v go >/dev/null 2>&1 || die "go toolchain not found on PATH"

git rev-parse --verify --quiet "$BASE_REF" >/dev/null \
  || die "base ref not found: $BASE_REF"
git rev-parse --verify --quiet "$HEAD_REF" >/dev/null \
  || die "head ref not found: $HEAD_REF"

# Both trees need the same benchmark files. Any *_benchmark_test.go present on head
# but missing on base is copied into the base worktree so both sides can run it.
mapfile -t BENCH_FILES < <(
  git ls-tree -r --name-only "$HEAD_REF" | grep '_benchmark_test\.go$' || true
)

RUN_ID="$$"
WT_BASE="${TMPDIR:-/tmp}/benchcmp-base-${RUN_ID}"
WT_HEAD="${TMPDIR:-/tmp}/benchcmp-head-${RUN_ID}"

cleanup() {
  if [ "$KEEP" = true ]; then
    echo "worktrees kept: $WT_BASE $WT_HEAD" >&2
    return
  fi
  git worktree remove --force "$WT_BASE" 2>/dev/null || true
  git worktree remove --force "$WT_HEAD" 2>/dev/null || true
}
trap cleanup EXIT

echo "Creating worktrees..." >&2
git worktree add --detach --quiet "$WT_BASE" "$BASE_REF"
git worktree add --detach --quiet "$WT_HEAD" "$HEAD_REF"

COPIED=()
for f in "${BENCH_FILES[@]}"; do
  [ -n "$f" ] || continue
  if [ ! -f "$WT_BASE/$f" ]; then
    mkdir -p "$(dirname "$WT_BASE/$f")"
    cp "$WT_HEAD/$f" "$WT_BASE/$f"
    COPIED+=("$f")
  fi
done

if [ ${#COPIED[@]} -gt 0 ]; then
  echo "Copied ${#COPIED[@]} benchmark file(s) into base tree so both sides can run them:" >&2
  printf '  %s\n' "${COPIED[@]}" >&2
fi

run_bench() {
  local dir=$1
  ( cd "$dir" && go test -bench="$BENCH_RE" -benchmem -count="$COUNT" "$PKG" 2>/dev/null ) \
    || die "benchmark run failed in $dir"
}

echo "Running benchmarks on $BASE_REF..." >&2
BASE_OUT=$(run_bench "$WT_BASE")
echo "Running benchmarks on $HEAD_REF..." >&2
HEAD_OUT=$(run_bench "$WT_HEAD")

# Parse "Name-12  123.4 ns/op  56 B/op  3 allocs/op" into "Name<TAB>ns<TAB>B<TAB>allocs".
# The CPU-count suffix (-12) is stripped so names match across machines/runs.
parse() {
  awk '
    /^Benchmark/ {
      name = $1
      sub(/-[0-9]+$/, "", name)
      ns = ""; bytes = ""; allocs = ""
      for (i = 2; i <= NF; i++) {
        if ($i == "ns/op") ns = $(i-1)
        else if ($i == "B/op") bytes = $(i-1)
        else if ($i == "allocs/op") allocs = $(i-1)
      }
      if (name != "") printf "%s\t%s\t%s\t%s\n", name, ns, bytes, allocs
    }
  ' <<< "$1"
}

BASE_ROWS=$(parse "$BASE_OUT")
HEAD_ROWS=$(parse "$HEAD_OUT")

# Report the minimum observed value per benchmark: with -count>1 the minimum is the
# least noisy estimate, and it is what should be quoted in a PR body.
best_of() {
  awk -F'\t' '
    { v = $2 + 0
      if (!($1 in min) || v < min[$1]) { min[$1] = v; b[$1] = $3; a[$1] = $4 } }
    END { for (k in min) printf "%s\t%s\t%s\t%s\n", k, min[k], b[k], a[k] }
  ' <<< "$1" | sort
}

BASE_BEST=$(best_of "$BASE_ROWS")
HEAD_BEST=$(best_of "$HEAD_ROWS")

BASE_NAMES=$(cut -f1 <<< "$BASE_BEST")
HEAD_NAMES=$(cut -f1 <<< "$HEAD_BEST")
ALL_NAMES=$(printf '%s\n%s\n' "$BASE_NAMES" "$HEAD_NAMES" | grep -v '^$' | sort -u)

field() { awk -F'\t' -v n="$1" -v c="$2" '$1 == n { print $c }' <<< "$3"; }

if [ "$AS_JSON" = true ]; then
  echo '{'
  echo '  "base_ref": "'"$BASE_REF"'",'
  echo '  "head_ref": "'"$HEAD_REF"'",'
  echo '  "count": '"$COUNT"','
  echo '  "bench": "'"$BENCH_RE"'",'
  echo '  "benchmarks": ['
  first=true
  while read -r name; do
    [ -n "$name" ] || continue
    b_ns=$(field "$name" 2 "$BASE_BEST")
    b_by=$(field "$name" 3 "$BASE_BEST")
    b_al=$(field "$name" 4 "$BASE_BEST")
    h_ns=$(field "$name" 2 "$HEAD_BEST")
    h_by=$(field "$name" 3 "$HEAD_BEST")
    h_al=$(field "$name" 4 "$HEAD_BEST")
    [ "$first" = true ] || echo ','
    first=false
    printf '    {"name": "%s", "base_ns": "%s", "base_bytes": "%s", "base_allocs": "%s", "head_ns": "%s", "head_bytes": "%s", "head_allocs": "%s"}' \
      "$name" "$b_ns" "$b_by" "$b_al" "$h_ns" "$h_by" "$h_al"
  done <<< "$ALL_NAMES"
  echo
  echo '  ]'
  echo '}'
  exit 0
fi

printf '| benchmark | %s | %s | delta |\n' "$BASE_REF" "$HEAD_REF"
printf '|---|---|---|---|\n'
# shellcheck disable=SC2016  # backticks in these format strings are literal Markdown, not command substitution
while read -r name; do
  [ -n "$name" ] || continue
  b_ns=$(field "$name" 2 "$BASE_BEST")
  b_by=$(field "$name" 3 "$BASE_BEST")
  b_al=$(field "$name" 4 "$BASE_BEST")
  h_ns=$(field "$name" 2 "$HEAD_BEST")
  h_by=$(field "$name" 3 "$HEAD_BEST")
  h_al=$(field "$name" 4 "$HEAD_BEST")

  if [ -z "$b_ns" ]; then
    printf '| `%s` | *absent on base* | %s ns, %s B/op, %s allocs/op | **new benchmark** |\n' \
      "$name" "$h_ns" "$h_by" "$h_al"
  elif [ -z "$h_ns" ]; then
    printf '| `%s` | %s ns, %s B/op, %s allocs/op | *absent on head* | **removed** |\n' \
      "$name" "$b_ns" "$b_by" "$b_al"
  else
    pct=$(awk -v b="$b_ns" -v h="$h_ns" 'BEGIN { if (b > 0) printf "%+.0f%%", (h - b) / b * 100; else print "n/a" }')
    printf '| `%s` | %s ns, %s B/op, %s allocs/op | %s ns, %s B/op, %s allocs/op | %s time |\n' \
      "$name" "$b_ns" "$b_by" "$b_al" "$h_ns" "$h_by" "$h_al" "$pct"
  fi
done <<< "$ALL_NAMES"

echo
echo "Minimum of $COUNT runs per benchmark. Reproduce with:" >&2
echo "  bash $0 $BASE_REF $HEAD_REF --bench '$BENCH_RE' --pkg '$PKG' --count $COUNT" >&2