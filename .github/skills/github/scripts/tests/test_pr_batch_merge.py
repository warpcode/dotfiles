"""Tests for github/scripts/pr_batch_merge.sh."""

import os
import subprocess
import tempfile
import unittest

SCRIPT_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "pr_batch_merge.sh")
)


class TestPrBatchMergeScript(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.bin_dir = os.path.join(self.temp_dir.name, "bin")
        os.makedirs(self.bin_dir, exist_ok=True)
        self.log_file = os.path.join(self.temp_dir.name, "gh_calls.log")

        gh_stub = os.path.join(self.bin_dir, "gh")
        with open(gh_stub, "w") as f:
            f.write(
                """#!/usr/bin/env bash
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"state":"OPEN","mergeable":"MERGEABLE","reviewDecision":"REVIEW_REQUIRED","statusCheckRollup":[{"conclusion":"SUCCESS"}],"title":"Test PR"}'
  exit 0
fi
exit 0
"""
            )
        os.chmod(gh_stub, 0o755)

    def _run(self, args):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"
        env["GH_CALL_LOG"] = self.log_file
        return subprocess.run(
            ["bash", SCRIPT_PATH] + args,
            capture_output=True,
            text=True,
            env=env,
        )

    def _read_log(self):
        if os.path.exists(self.log_file):
            with open(self.log_file) as f:
                return f.read().splitlines()
        return []

    def test_defaults_are_safe_no_admin_no_delete_branch(self):
        res = self._run(["--repo", "octocat/hello", "42"])
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        logs = self._read_log()
        merge_calls = [line for line in logs if line.startswith("pr merge 42 ")]
        self.assertEqual(len(merge_calls), 1)
        self.assertIn("--squash", merge_calls[0])
        self.assertNotIn("--admin", merge_calls[0])
        self.assertNotIn("--delete-branch", merge_calls[0])

    def test_explicit_admin_and_delete_branch_flags(self):
        res = self._run(
            ["--repo", "octocat/hello", "--admin", "--delete-branch", "42"]
        )
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        logs = self._read_log()
        merge_calls = [line for line in logs if line.startswith("pr merge 42 ")]
        self.assertEqual(len(merge_calls), 1)
        self.assertIn("--admin", merge_calls[0])
        self.assertIn("--delete-branch", merge_calls[0])

    def test_explicit_no_admin_and_no_delete_branch_flags(self):
        res = self._run(
            ["--repo", "octocat/hello", "--no-admin", "--no-delete-branch", "42"]
        )
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        logs = self._read_log()
        merge_calls = [line for line in logs if line.startswith("pr merge 42 ")]
        self.assertEqual(len(merge_calls), 1)
        self.assertNotIn("--admin", merge_calls[0])
        self.assertNotIn("--delete-branch", merge_calls[0])

    def test_dry_run_skips_review_and_merge(self):
        res = self._run(["--repo", "octocat/hello", "--dry-run", "42"])
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("[DRY RUN] Eligible for merge: PR #42", res.stdout)
        logs = self._read_log()
        self.assertFalse(any("pr review" in line for line in logs))
        self.assertFalse(any("pr merge" in line for line in logs))


if __name__ == "__main__":
    unittest.main()
