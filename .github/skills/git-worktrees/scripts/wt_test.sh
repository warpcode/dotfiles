#!/usr/bin/env bash
#
# wt_test.sh: Execute a command/tests inside an isolated worktree directory and print a summary.
#
# Usage: wt_test.sh <worktree-path> <command> [args...]
#
# Examples:
#   wt_test.sh /tmp/tidy-37 pytest
#   wt_test.sh /tmp/wt-feature-123 go test ./...
#   wt_test.sh /tmp/tidy-39 git cherry-pick -n 22f67f49a663c2c10b188e23d333378
#

set -euo pipefail
export PAGER=cat

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

print_usage() {
  cat <<'USAGE_EOF'
Usage: wt_test.sh <worktree-path> <command> [args...]

Arguments:
  <worktree-path>   Path to the worktree directory
  <command>         Command to execute inside the worktree
  [args...]         Optional arguments passed to the command

Options:
  -h, --help        Show this help message
USAGE_EOF
}

if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  print_usage
  if [[ $# -lt 1 ]]; then
    exit 1
  fi
  exit 0
fi

if [[ $# -lt 2 ]]; then
  err "Missing command to execute."
  print_usage >&2
  exit 1
fi

worktree_path="$1"
shift

if [[ ! -d "${worktree_path}" ]]; then
  err "Worktree directory does not exist: ${worktree_path}"
  exit 1
fi

# Detect git branch or ref if inside a git repository
branch=""
if git -C "${worktree_path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "${worktree_path}" branch --show-current 2>/dev/null || true)"
  if [[ -z "${branch}" ]]; then
    branch="$(git -C "${worktree_path}" rev-parse --short HEAD 2>/dev/null || echo "detached")"
  fi
else
  branch="non-git"
fi

cmd_str="$*"

echo "=== Executing in worktree: ${worktree_path} (branch: ${branch}) ==="
echo "=== Command: ${cmd_str} ==="

start_time="$(date +%s)"
cmd_status=0

# Execute command inside worktree directory
(
  cd "${worktree_path}"
  "$@"
) || cmd_status=$?

end_time="$(date +%s)"
duration=$(( end_time - start_time ))

echo ""
echo "=== Worktree Execution Summary ==="
echo "Worktree: ${worktree_path}"
echo "Branch:   ${branch}"
echo "Command:  ${cmd_str}"
if [[ ${cmd_status} -eq 0 ]]; then
  echo "Status:   SUCCESS (exit code 0)"
else
  echo "Status:   FAILED (exit code ${cmd_status})"
fi
echo "Duration: ${duration}s"
echo "=================================="

exit ${cmd_status}
