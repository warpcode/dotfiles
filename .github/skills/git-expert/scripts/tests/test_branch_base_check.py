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

    def test_stale_remote_tracking_ref_is_refreshed(self):
        """Regression: the fetch used the *ref* name as the remote, so it always
        failed silently and the check judged ancestry against a stale base.

        With a stale `origin/master`, the original script reported PASS for a
        branch cut from a sibling feature branch -- exactly the condition the
        script exists to catch. The fetch must actually refresh the base ref.
        """
        upstream = tempfile.mkdtemp()
        upstream = os.path.join(upstream, "upstream.git")
        subprocess.run(["git", "init", "-q", "--bare", upstream], check=True)

        # Publish master as the remote base.
        _git(self.repo, "remote", "add", "origin", upstream)
        _git(self.repo, "push", "-q", "origin", "master")

        # A sibling feature branch is cut and published.
        _git(self.repo, "checkout", "-b", "sibling")
        _git(self.repo, "commit", "--allow-empty", "-m", "sibling work")
        _git(self.repo, "push", "-q", "origin", "sibling")

        # master advances upstream; the local remote-tracking ref goes stale.
        _git(self.repo, "checkout", "master")
        _git(self.repo, "commit", "--allow-empty", "-m", "master moves on")
        _git(self.repo, "push", "-q", "origin", "master")

        # The bad branch is cut from the sibling, not from master.
        _git(self.repo, "checkout", "-b", "bad", "sibling")
        _git(self.repo, "commit", "--allow-empty", "-m", "my change")

        # Force the tracking ref back to the pre-advance commit: a genuinely
        # stale base that ancestry alone cannot distinguish from a good branch.
        subprocess.run(
            ["git", "-C", self.repo, "update-ref", "refs/remotes/origin/master",
             subprocess.run(["git", "-C", self.repo, "rev-parse", "sibling^"],
                            capture_output=True, text=True, check=True).stdout.strip()],
            check=True)

        res = subprocess.run([BRANCH_BASE_CHECK, "--base", "origin/master",
                              "--head", "bad"], cwd=self.repo,
                             capture_output=True, text=True)
        self.assertEqual(
            res.returncode, 1,
            "a branch cut from a sibling must fail even when origin/master is "
            "stale -- the fetch should have refreshed the base ref first")
        self.assertIn("FAIL", res.stderr)

    def test_json_has_no_duplicate_foreign_commits_field(self):
        """Regression: `foreign_commits` was computed identically to `ahead`,
        so the two JSON fields always carried the same number."""
        _git(self.repo, "checkout", "-b", "good")
        _git(self.repo, "commit", "--allow-empty", "-m", "feature work")
        res = self._run("--head", "good", "--json")
        self.assertEqual(res.returncode, 0)
        data = json.loads(res.stdout)
        self.assertNotIn("foreign_commits", data)
        self.assertIn("ahead", data)
        self.assertIn("behind", data)

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