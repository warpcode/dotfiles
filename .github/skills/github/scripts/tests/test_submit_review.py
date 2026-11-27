"""Tests for github/scripts/submit_review.sh."""

import json
import os
import subprocess
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "submit_review.sh")
)


class SubmitReviewTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.base = self._tmp.name
        self.repo = os.path.join(self.base, "repo")
        self.remote = os.path.join(self.base, "remote.git")
        self.bin_dir = os.path.join(self.base, "bin")
        os.makedirs(self.repo)
        os.makedirs(self.bin_dir)

        self._git("init", "-q", "--bare", "-b", "main", self.remote)
        self._git("init", "-q", "-b", "main", self.repo)
        self._git("config", "user.email", "a@b")
        self._git("config", "user.name", "a")
        with open(os.path.join(self.repo, "f.txt"), "w") as fh:
            fh.write("line1\n")
        self._git("add", "-A")
        self._git("commit", "-qm", "base")
        self._git("remote", "add", "origin", self.remote)
        self._git("push", "-q", "origin", "main")

        self._git("checkout", "-q", "-b", "feat")
        with open(os.path.join(self.repo, "f.txt"), "w") as fh:
            fh.write("line1\nline2\n")
        self._git("add", "-A")
        self._git("commit", "-qm", "feat")
        self._git("push", "-q", "origin", "feat:refs/pull/7/head")

        self.spec_path = os.path.join(self.base, "spec.json")
        with open(self.spec_path, "w") as fh:
            json.dump(
                [
                    {
                        "path": "f.txt",
                        "line": 2,
                        "severity": "Low",
                        "title": "Check line2",
                        "description": "Added line2 needs check.",
                        "impact": "Minor risk.",
                        "solution": "Review line2.",
                    }
                ],
                fh,
            )

        self.gh_log = os.path.join(self.base, "gh.log")
        gh_stub = os.path.join(self.bin_dir, "gh")
        with open(gh_stub, "w") as fh:
            fh.write(
                """#!/usr/bin/env bash
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "diff" ]]; then
  cat <<'DIFF'
diff --git a/f.txt b/f.txt
--- a/f.txt
+++ b/f.txt
@@ -1 +1,2 @@
 line1
+line2
DIFF
  exit 0
fi
if [[ "$1" == "api" ]]; then
  echo '{"html_url":"https://github.com/octocat/hello/pull/7#pullrequestreview-1","state":"CHANGES_REQUESTED"}'
  exit 0
fi
if [[ "$1" == "repo" && "$2" == "view" ]]; then
  exit 1
fi
exit 0
"""
            )
        os.chmod(gh_stub, 0o755)

    def _git(self, *args):
        subprocess.run(
            ["git"] + list(args),
            cwd=self.repo,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )

    def _run(self, args):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"
        env["GH_CALL_LOG"] = self.gh_log
        return subprocess.run(
            ["bash", SCRIPT] + args,
            cwd=self.repo,
            capture_output=True,
            text=True,
            env=env,
        )

    def _read_gh_log(self):
        if not os.path.exists(self.gh_log):
            return []
        with open(self.gh_log) as fh:
            return fh.read().splitlines()

    def test_combined_repo_flag_validate_only(self):
        res = self._run(
            [
                "--spec",
                self.spec_path,
                "--repo",
                "octocat/hello",
                "--pr",
                "7",
                "--validate-only",
            ]
        )
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("anchors verified", res.stdout)
        logs = self._read_gh_log()
        self.assertTrue(any("pr diff 7 --repo octocat/hello" in line for line in logs))

    def test_legacy_owner_and_repo_flags_submit(self):
        res = self._run(
            [
                "--spec",
                self.spec_path,
                "--owner",
                "octocat",
                "--repo",
                "hello",
                "--pr",
                "7",
            ]
        )
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("Review submitted successfully", res.stdout)
        logs = self._read_gh_log()
        self.assertTrue(
            any("api repos/octocat/hello/pulls/7/reviews" in line for line in logs)
        )

    def test_conflicting_owner_and_combined_repo_rejected(self):
        res = self._run(
            [
                "--spec",
                self.spec_path,
                "--owner",
                "octocat",
                "--repo",
                "other/hello",
                "--pr",
                "7",
                "--validate-only",
            ]
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("not both", res.stderr)


if __name__ == "__main__":
    unittest.main()
