"""Tests for github-pr-review/scripts/reply_to_review_thread.sh."""

import os
import subprocess
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "reply_to_review_thread.sh")
)


class ReplyToReviewThreadTests(unittest.TestCase):
    def test_help(self):
        res = subprocess.run([SCRIPT, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage:", res.stdout)
        self.assertIn("--comment-id", res.stdout)

    def test_missing_args(self):
        res = subprocess.run([SCRIPT], capture_output=True, text=True)
        self.assertEqual(res.returncode, 1)
        self.assertIn("missing required --pr", res.stderr)

        res = subprocess.run([SCRIPT, "--pr", "42"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 1)
        self.assertIn("missing required --comment-id", res.stderr)

        res = subprocess.run(
            [SCRIPT, "--pr", "42", "--comment-id", "123"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("missing required --body", res.stderr)

    def test_non_integer_comment_id(self):
        res = subprocess.run(
            [
                SCRIPT,
                "--owner",
                "foo",
                "--repo",
                "bar",
                "--pr",
                "42",
                "--comment-id",
                "PRRC_abc123",
                "--body",
                "test",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("--comment-id must be an integer REST databaseId", res.stderr)

    def test_dry_run_explicit_owner_repo(self):
        res = subprocess.run(
            [
                SCRIPT,
                "--owner",
                "warpcode",
                "--repo",
                "dotfiles",
                "--pr",
                "171",
                "--comment-id",
                "4224610189",
                "--body",
                "Test reply body",
                "--dry-run",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn(
            "POST /repos/warpcode/dotfiles/pulls/171/comments/4224610189/replies",
            res.stdout,
        )
        self.assertIn("body: Test reply body", res.stdout)

    def test_dry_run_combined_repo_slug(self):
        res = subprocess.run(
            [
                SCRIPT,
                "--repo",
                "warpcode/dotfiles",
                "--pr",
                "171",
                "--comment-id",
                "4224610189",
                "--body",
                "Combined slug reply",
                "--dry-run",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn(
            "POST /repos/warpcode/dotfiles/pulls/171/comments/4224610189/replies",
            res.stdout,
        )
        self.assertIn("body: Combined slug reply", res.stdout)


if __name__ == "__main__":
    unittest.main()
