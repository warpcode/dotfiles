"""End-to-end tests for review-pull-request/scripts/mutation_check.sh.

The three verdicts are the whole point of the script, because they separate an
actionable finding from a non-finding:

  KILLED        this PR's tests catch the mutation -> no finding
  SURVIVED      no test catches it                -> this PR's gap, report it
  PRE-EXISTING  the base branch also fails         -> repo-wide, follow-up only

That distinction is what SKILL.md learned the hard way on 2026-10-03
(warpcode/cloakenv#209), so it is pinned here. The fixtures use a real Go
module and real `go test` runs rather than a stubbed runner.

Skipped when `go` is unavailable, since CI for this repo does not install it.
"""

import json
import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "mutation_check.sh")
)

GO_AVAILABLE = shutil.which("go") is not None

BASE_GUARD = '''package pkg

// ValidateKey predates the PR and is already covered on main.
func ValidateKey(ok bool, key string) bool {
\tif ok && key != "" {
\t\treturn true
\t}
\treturn false
}
'''

BASE_GUARD_TEST = '''package pkg

import "testing"

func TestValidateKey(t *testing.T) {
\tif ValidateKey(true, "") {
\t\tt.Error("empty key must be rejected")
\t}
}
'''

HEAD_GUARD = '''package pkg

// NormalizeKey is added by the PR under review.
func NormalizeKey(key string) string {
\tif key == "" {
\t\treturn "fallback"
\t}
\treturn key
}
'''

HEAD_GUARD_TEST = '''package pkg

import "testing"

func TestNormalizeKey(t *testing.T) {
\tif got := NormalizeKey("HOME"); got != "HOME" {
\t\tt.Errorf("passthrough: got %q", got)
\t}
\tif got := NormalizeKey(""); got != "fallback" {
\t\tt.Errorf("empty key: got %q want fallback", got)
\t}
}
'''

ORPHAN = '''package pkg

// StripQuotes has a branch no test in the repo reaches.
func StripQuotes(s string) string {
\tif len(s) > 1 && s[0] == '"' && s[len(s)-1] == '"' {
\t\treturn s[1 : len(s)-1]
\t}
\treturn s
}
'''

ORPHAN_TEST = '''package pkg

import "testing"

func TestStripQuotesPassthrough(t *testing.T) {
\tif got := StripQuotes("plain"); got != "plain" {
\t\tt.Errorf("got %q", got)
\t}
}
'''


@unittest.skipUnless(GO_AVAILABLE, "go toolchain not installed")
class MutationCheckTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.base = self._tmp.name
        self.repo = os.path.join(self.base, "repo")
        self.remote = os.path.join(self.base, "remote.git")
        self.root = os.path.join(self.base, "wt")
        os.makedirs(os.path.join(self.repo, "pkg"))

        self._git("init", "-q", "--bare", "-b", "main", self.remote)
        self._git("init", "-q", "-b", "main", self.repo)
        self.git("config", "user.email", "a@b")
        self.git("config", "user.name", "a")

        self.write("go.mod", "module example.com/mut\n\ngo 1.22\n")
        self.write("pkg/pre_existing.go", BASE_GUARD)
        self.write("pkg/pre_existing_test.go", BASE_GUARD_TEST)
        self.git("add", "-A")
        self.git("commit", "-qm", "base")
        self.git("remote", "add", "origin", self.remote)
        self.git("push", "-q", "origin", "main")

        self.git("checkout", "-q", "-b", "feat")
        self.write("pkg/guard.go", HEAD_GUARD)
        self.write("pkg/guard_test.go", HEAD_GUARD_TEST)
        self.write("pkg/orphan.go", ORPHAN)
        self.write("pkg/orphan_test.go", ORPHAN_TEST)
        self.git("add", "-A")
        self.git("commit", "-qm", "pr change")
        self.git("push", "-q", "origin", "feat:refs/pull/9/head")

        self.addCleanup(self._cleanup_worktrees)

    def _git(self, *args):
        return subprocess.run(["git"] + list(args), cwd=self.repo,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                              check=True)

    def git(self, *args):
        return self._git(*args)

    def _cleanup_worktrees(self):
        wt = os.path.abspath(os.path.join(os.path.dirname(__file__), "..",
                                          "review_worktree.sh"))
        subprocess.run(["bash", wt, "rm", "--pr", "9", "--all-roles", "--force",
                        "--root", self.root],
                       cwd=self.repo, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)

    def write(self, name, content):
        with open(os.path.join(self.repo, name), "w") as fh:
            fh.write(content)

    def spec(self, mutations):
        path = os.path.join(self.base, "muts.json")
        with open(path, "w") as fh:
            json.dump(mutations, fh)
        return path

    def run_check(self, spec_path, *extra):
        return subprocess.run(
            ["bash", SCRIPT, "--pr", "9", "--spec", spec_path,
             "--test-cmd", "go test ./pkg/ -count=1", "--root", self.root,
             *extra],
            cwd=self.repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            timeout=300)

    # --- verdicts -------------------------------------------------------------

    def test_all_three_verdicts_and_the_named_failing_test(self):
        spec = self.spec([
            {"name": "M1 drop empty-key fallback",
             "path": "pkg/guard.go",
             "old": '\tif key == "" {\n\t\treturn "fallback"\n\t}',
             "new": ""},
            {"name": "M2 neuter ValidateKey guard",
             "path": "pkg/pre_existing.go",
             "old": '\tif ok && key != "" {\n\t\treturn true\n\t}',
             "new": '\tif ok {\n\t\treturn true\n\t}'},
            {"name": "M3 disable StripQuotes branch",
             "path": "pkg/orphan.go",
             "old": '\tif len(s) > 1 && s[0] == \'"\' && s[len(s)-1] == \'"\' {',
             "new": "\tif false {"},
        ])
        res = self.run_check(spec)
        out = res.stdout
        self.assertIn("**KILLED**", out)
        self.assertIn("**SURVIVED**", out)
        self.assertIn("**PRE-EXISTING**", out)
        # Rule 3: report which subtest caught it, by name.
        self.assertIn("TestNormalizeKey", out)
        self.assertIn("TestValidateKey", out)
        # A surviving mutation is a finding, so it must not pass.
        self.assertEqual(res.returncode, 1)
        self.assertIn("survived", res.stderr)

    def test_all_mutations_killed_exits_zero(self):
        spec = self.spec([
            {"name": "M1 drop empty-key fallback",
             "path": "pkg/guard.go",
             "old": '\tif key == "" {\n\t\treturn "fallback"\n\t}',
             "new": ""},
        ])
        res = self.run_check(spec)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("killed=1 survived=0", res.stdout)

    def test_skip_base_cannot_report_pre_existing(self):
        spec = self.spec([
            {"name": "M2 neuter ValidateKey guard",
             "path": "pkg/pre_existing.go",
             "old": '\tif ok && key != "" {\n\t\treturn true\n\t}',
             "new": '\tif ok {\n\t\treturn true\n\t}'},
        ])
        res = self.run_check(spec, "--skip-base")
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertNotIn("PRE-EXISTING", res.stdout)

    # --- a mutation that did not apply proves nothing -------------------------

    def test_pattern_that_does_not_apply_is_a_hard_error(self):
        spec = self.spec([
            {"name": "M bad", "path": "pkg/guard.go",
             "old": "this text is not in the file", "new": "x"},
        ])
        res = self.run_check(spec)
        self.assertEqual(res.returncode, 2)
        self.assertIn("never applied", res.stderr)

    def test_pattern_present_on_head_but_absent_on_base_is_not_a_failure(self):
        spec = self.spec([
            {"name": "M pr-only branch", "path": "pkg/guard.go",
             "old": '\tif key == "" {\n\t\treturn "fallback"\n\t}',
             "new": ""},
        ])
        res = self.run_check(spec)
        self.assertNotEqual(res.returncode, 2, res.stdout + res.stderr)

    # --- hygiene --------------------------------------------------------------

    def test_worktrees_are_removed_on_exit(self):
        spec = self.spec([
            {"name": "M1", "path": "pkg/guard.go",
             "old": '\tif key == "" {\n\t\treturn "fallback"\n\t}', "new": ""},
        ])
        self.run_check(spec)
        out = subprocess.run(
            ["git", "worktree", "list", "--porcelain"], cwd=self.repo,
            stdout=subprocess.PIPE, text=True, check=True).stdout
        paths = [ln.split(" ", 1)[1] for ln in out.splitlines()
                 if ln.startswith("worktree ")][1:]
        self.assertEqual(paths, [], f"leaked worktrees: {paths}")

    def test_source_files_are_restored_after_each_mutation(self):
        spec = self.spec([
            {"name": "M1", "path": "pkg/guard.go",
             "old": '\tif key == "" {\n\t\treturn "fallback"\n\t}', "new": ""},
            {"name": "M3", "path": "pkg/orphan.go",
             "old": '\tif len(s) > 1', "new": "\tif false"},
        ])
        self.run_check(spec, "--keep")
        for path in (os.path.join(self.root, "pr9-head"),
                     os.path.join(self.root, "pr9-base")):
            if os.path.isdir(path):
                dirty = subprocess.run(
                    ["git", "status", "--porcelain"], cwd=path,
                    stdout=subprocess.PIPE, text=True).stdout
                self.assertEqual(dirty.strip(), "", f"{path} left mutated")

    def test_usage_errors(self):
        self.assertNotEqual(
            subprocess.run(["bash", SCRIPT, "--pr", "9"],
                           cwd=self.repo, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE).returncode, 0)
        spec = self.spec([{"name": "x", "path": "pkg/guard.go",
                           "old": "a", "new": "b"}])
        res = subprocess.run(
            ["bash", SCRIPT, "--pr", "9", "--spec", spec],
            cwd=self.repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("--test-cmd is required", res.stderr)


if __name__ == "__main__":
    unittest.main()