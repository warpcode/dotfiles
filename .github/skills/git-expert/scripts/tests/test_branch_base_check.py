import json
import os
import subprocess
import tempfile
import unittest

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BRANCH_BASE_CHECK = os.path.join(SCRIPTS_DIR, "branch_base_check.sh")


def _git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True)


class TestBranchBaseCheck(unittest.TestCase):
    """Regression tests for the 2026-10-10 incident: a branch cut from a stale
    feature branch (not from the base) produced a CONFLICTING PR."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = self._tmp.name
        subprocess.run(["git", "init", "-b", "master", self.repo],
                       capture_output=True, check=True)
        _git(self.repo, "config", "user.name", "Test")
        _git(self.repo, "config", "user.email", "test@example.com")
        _git(self.repo, "commit", "--allow-empty", "-m", "base")

    def tearDown(self):
        self._tmp.cleanup()

    def _run(self, *args):
        # cwd matters: the script operates on the git repo in the current
        # directory, matching push.sh/sync.sh convention.
        return subprocess.run([BRANCH_BASE_CHECK, "--base", "master", *args],
                              cwd=self.repo, capture_output=True, text=True)

    def test_help_documents_flags(self):
        res = subprocess.run([BRANCH_BASE_CHECK, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        for flag in ("--base", "--head", "--json"):
            self.assertIn(flag, res.stdout)

    def test_passes_when_branched_from_base(self):
        _git(self.repo, "checkout", "-b", "good")
        _git(self.repo, "commit", "--allow-empty", "-m", "feature work")
        res = self._run("--head", "good")
        self.assertEqual(res.returncode, 0)
        self.assertIn("PASS", res.stdout)

    def test_fails_when_branched_from_stale_feature_branch(self):
        # base advances after the feature branch is cut, creating divergence
        _git(self.repo, "checkout", "-b", "feature")
        _git(self.repo, "commit", "--allow-empty", "-m", "feature work")
        _git(self.repo, "checkout", "master")
        _git(self.repo, "commit", "--allow-empty", "-m", "master moves on")
        # branch off the stale feature branch -- the original mistake
        _git(self.repo, "checkout", "-b", "bad", "feature")
        _git(self.repo, "commit", "--allow-empty", "-m", "my change")

        res = self._run("--head", "bad")
        self.assertEqual(res.returncode, 1, "divergent branch must fail")
        self.assertIn("FAIL", res.stderr)

    def test_json_output_is_pure_json_on_failure(self):
        _git(self.repo, "checkout", "-b", "feature")
        _git(self.repo, "commit", "--allow-empty", "-m", "feature work")
        _git(self.repo, "checkout", "master")
        _git(self.repo, "commit", "--allow-empty", "-m", "master moves on")
        _git(self.repo, "checkout", "-b", "bad", "feature")
        _git(self.repo, "commit", "--allow-empty", "-m", "my change")

        res = self._run("--head", "bad", "--json")
        self.assertEqual(res.returncode, 1)
        # stdout must parse on its own -- no human text interleaved
        data = json.loads(res.stdout)
        self.assertIs(data["is_ancestor"], False)
        self.assertGreater(data["behind"], 0)

    def test_json_success_reports_true(self):
        _git(self.repo, "checkout", "-b", "good")
        _git(self.repo, "commit", "--allow-empty", "-m", "feature work")
        res = self._run("--head", "good", "--json")
        self.assertEqual(res.returncode, 0)
        self.assertIs(json.loads(res.stdout)["is_ancestor"], True)

    def test_unknown_flag_is_usage_error(self):
        res = subprocess.run([BRANCH_BASE_CHECK, "--nope"],
                             cwd=self.repo, capture_output=True, text=True)
        self.assertEqual(res.returncode, 2)

    def test_missing_value_is_usage_error(self):
        res = subprocess.run([BRANCH_BASE_CHECK, "--base"],
                             cwd=self.repo, capture_output=True, text=True)
        self.assertEqual(res.returncode, 2)

    def test_missing_base_ref_fails_loudly(self):
        res = subprocess.run([BRANCH_BASE_CHECK, "--base", "origin/does-not-exist",
                              "--head", "HEAD"], cwd=self.repo,
                             capture_output=True, text=True)
        self.assertEqual(res.returncode, 1)
        self.assertIn("not found", res.stderr)


if __name__ == "__main__":
    unittest.main()