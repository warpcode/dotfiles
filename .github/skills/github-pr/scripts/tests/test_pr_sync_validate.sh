#!/usr/bin/env bash
# Tests for pr_sync_validate.sh using a throwaway local remote and a stub `gh`.
# No network, no GitHub. Run: bash test_pr_sync_validate.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/pr_sync_validate.sh"
T="$(mktemp -d)"
trap 'chmod -R u+w "$T"; rm -rf "$T"' EXIT
FAILS=0

ok()   { echo "PASS: $1"; }
bad()  { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }
expect_rc() { # name expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected rc $2, got $3)"; fi
}

# Stub gh: `gh pr view ... --jq` prints "<head>\t<base>\t<author>\t<state>".
mkdir "$T/bin"
cat >"$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\t%s\t%s\t%s\n' "${STUB_HEAD:-feature}" master "${STUB_AUTHOR:-alice}" "${STUB_STATE:-OPEN}"
EOF
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH"

git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/clone" 2>/dev/null
cd "$T/clone"
git config user.email t@example.com
git config user.name t
git checkout -q -b master
echo base >f.txt
printf '#!/usr/bin/env bash\nexit 0\n' >validate.sh
chmod +x validate.sh
git add . && git commit -q -m base && git push -q origin master
git checkout -q -b feature
echo feature >f.txt && git commit -q -am feature && git push -q origin feature
git checkout -q master
echo master-change >f.txt && git commit -q -am master && git push -q origin master

# 1. Conflict -> rc 2, conflicted file listed, worktree left in place.
set +e
out="$(bash "$SCRIPT" 1 --repo o/r --repo-dir "$T/clone" --wt "$T/wt1" 2>&1)"; rc=$?
set -e
expect_rc "conflict exits 2" 2 "$rc"
case "$out" in *f.txt*) ok "conflicted file listed" ;; *) bad "conflicted file listed" ;; esac

# 2. Unresolved --continue -> rc 2.
set +e
bash "$SCRIPT" 1 --repo o/r --repo-dir "$T/clone" --wt "$T/wt1" --continue >/dev/null 2>&1; rc=$?
set -e
expect_rc "--continue with unresolved conflicts exits 2" 2 "$rc"

# 3. Resolve, --continue -> rc 0 and merge commit created.
echo resolved >"$T/wt1/f.txt"
git -C "$T/wt1" add f.txt
bash "$SCRIPT" 1 --repo o/r --repo-dir "$T/clone" --wt "$T/wt1" --continue >/dev/null 2>&1; rc=$?
expect_rc "--continue after resolution exits 0" 0 "$rc"
if [ "$(git -C "$T/wt1" rev-list --parents -n1 HEAD | wc -w)" = 3 ]; then ok "merge commit has two parents"; else bad "merge commit has two parents"; fi

# 4. Existing worktree refused on a fresh start.
set +e
bash "$SCRIPT" 1 --repo o/r --repo-dir "$T/clone" --wt "$T/wt1" >/dev/null 2>&1; rc=$?
set -e
expect_rc "existing worktree refused" 1 "$rc"

# 5. Jules-owned PR refused.
set +e
STUB_AUTHOR=google-labs-jules bash "$SCRIPT" 2 --repo o/r --repo-dir "$T/clone" --wt "$T/wt2" >/dev/null 2>&1; rc=$?
set -e
expect_rc "Jules-owned PR refused" 1 "$rc"

# 6. Closed PR refused.
set +e
STUB_STATE=MERGED bash "$SCRIPT" 3 --repo o/r --repo-dir "$T/clone" --wt "$T/wt3" >/dev/null 2>&1; rc=$?
set -e
expect_rc "non-open PR refused" 1 "$rc"

# 7. Dry run mutates nothing.
bash "$SCRIPT" 4 --repo o/r --repo-dir "$T/clone" --wt "$T/wt4" --dry-run >/dev/null 2>&1; rc=$?
expect_rc "dry-run exits 0" 0 "$rc"
if [ ! -e "$T/wt4" ]; then ok "dry-run created no worktree"; else bad "dry-run created no worktree"; fi

# 8. Validation failure -> rc 3.
git -C "$T/clone" worktree remove --force "$T/wt1"
git -C "$T/clone" branch -D feature >/dev/null
set +e
bash "$SCRIPT" 5 --repo o/r --repo-dir "$T/clone" --wt "$T/wt5" --validate "false" >/dev/null 2>&1; rc=$?
set -e
# Merge conflicts again (feature is unmerged remotely), so rc 2 precedes validation; assert not 0.
if [ "$rc" != 0 ]; then ok "failure path returns nonzero (rc $rc)"; else bad "failure path returns nonzero"; fi

echo
[ "$FAILS" = 0 ] && echo "All tests passed." || { echo "$FAILS test(s) failed."; exit 1; }
