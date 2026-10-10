#!/usr/bin/env python3
"""Unit tests for pr_worktree_sync.sh in github-pr skill."""

import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPT_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "pr_worktree_sync.sh")
)


class TestPrWorktreeSync(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.repo = os.path.join(self.tmpdir, "repo")
        os.makedirs(self.repo)

        # Initialize main git repo
        self.git("init", "-b", "master", cwd=self.repo)
        self.git("config", "user.name", "Test User", cwd=self.repo)
        self.git("config", "user.email", "test@example.com", cwd=self.repo)

        # Initial commit on master
        readme = os.path.join(self.repo, "README.md")
        with open(readme, "w") as f:
            f.write("# Main Readme\n")
        self.git("add", "README.md", cwd=self.repo)
        self.git("commit", "-m", "Initial commit on master", cwd=self.repo)

    def tearDown(self):
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def git(self, *args, cwd=None):
        cmd = ["git"] + list(args)
        res = subprocess.run(
            cmd,
            cwd=cwd or self.repo,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        return res.stdout

    def run_script(self, *args, cwd=None):
        cmd = [SCRIPT_PATH] + list(args)
        res = subprocess.run(
            cmd,
            cwd=cwd or self.repo,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return res

    def test_help_flag(self):
        res = self.run_script("--help")
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage:", res.stdout)
        self.assertIn("setup", res.stdout)
        self.assertIn("cleanup", res.stdout)

    def test_missing_branch_flag(self):
        res = self.run_script("setup")
        self.assertEqual(res.returncode, 1)
        self.assertIn("--branch is required", res.stderr)

    def test_setup_clean_merge_and_cleanup(self):
        # Create a feature branch with non-conflicting change
        self.git("checkout", "-b", "feature-clean", cwd=self.repo)
        feature_file = os.path.join(self.repo, "feature.txt")
        with open(feature_file, "w") as f:
            f.write("feature content\n")
        self.git("add", "feature.txt", cwd=self.repo)
        self.git("commit", "-m", "Add feature file", cwd=self.repo)
        self.git("checkout", "master", cwd=self.repo)

        # Commit an unrelated file on master
        master_file = os.path.join(self.repo, "master.txt")
        with open(master_file, "w") as f:
            f.write("master content\n")
        self.git("add", "master.txt", cwd=self.repo)
        self.git("commit", "-m", "Add master file", cwd=self.repo)

        wt_dir = os.path.join(self.tmpdir, "wt-clean")
        res = self.run_script(
            "setup",
            "--branch", "feature-clean",
            "--base", "master",
            "--dir", wt_dir,
            "--no-fetch",
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("PR Worktree Sync: Success", res.stdout)
        self.assertTrue(os.path.exists(wt_dir))
        self.assertTrue(os.path.exists(os.path.join(wt_dir, "master.txt")))
        self.assertTrue(os.path.exists(os.path.join(wt_dir, "feature.txt")))

        # Check status
        status_res = self.run_script("status", "--dir", wt_dir)
        self.assertEqual(status_res.returncode, 0)
        self.assertIn("State: CLEAN", status_res.stdout)

        # Cleanup
        cleanup_res = self.run_script("cleanup", "--dir", wt_dir)
        self.assertEqual(cleanup_res.returncode, 0)
        self.assertFalse(os.path.exists(wt_dir))

    def test_setup_conflict_detection(self):
        # Create a feature branch editing README.md
        self.git("checkout", "-b", "feature-conflict", cwd=self.repo)
        readme = os.path.join(self.repo, "README.md")
        with open(readme, "w") as f:
            f.write("# Feature Conflict Version\n")
        self.git("add", "README.md", cwd=self.repo)
        self.git("commit", "-m", "Update README on feature", cwd=self.repo)
        self.git("checkout", "master", cwd=self.repo)

        # Commit conflicting change to README.md on master
        with open(readme, "w") as f:
            f.write("# Master Conflict Version\n")
        self.git("add", "README.md", cwd=self.repo)
        self.git("commit", "-m", "Update README on master", cwd=self.repo)

        wt_dir = os.path.join(self.tmpdir, "wt-conflict")
        res = self.run_script(
            "setup",
            "--branch", "feature-conflict",
            "--base", "master",
            "--dir", wt_dir,
            "--no-fetch",
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("PR Worktree Sync: Conflict Detected", res.stdout)
        self.assertIn("README.md", res.stdout)

        # Verify status reports MERGING state
        status_res = self.run_script("status", "--dir", wt_dir)
        self.assertEqual(status_res.returncode, 0)
        self.assertIn("State: MERGING", status_res.stdout)
        self.assertIn("README.md", status_res.stdout)

        # Cleanup
        cleanup_res = self.run_script("cleanup", "--dir", wt_dir)
        self.assertEqual(cleanup_res.returncode, 0)
        self.assertFalse(os.path.exists(wt_dir))


if __name__ == "__main__":
    unittest.main()
