#!/usr/bin/env python3
"""Unit and integration tests for worktrees.sh in git-worktrees skill."""

import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPT_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "worktrees.sh")
)


class TestWorktreesScript(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.repo = os.path.join(self.tmpdir, "repo")
        os.makedirs(self.repo)

        # Initialize a main git repository
        self.git("init", cwd=self.repo)
        self.git("config", "user.name", "Test User", cwd=self.repo)
        self.git("config", "user.email", "test@example.com", cwd=self.repo)

        # Create an initial commit
        readme = os.path.join(self.repo, "README.md")
        with open(readme, "w") as f:
            f.write("# Test Repo\n")
        self.git("add", "README.md", cwd=self.repo)
        self.git("commit", "-m", "Initial commit", cwd=self.repo)

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

    def test_raw_output(self):
        wt_path = os.path.join(self.tmpdir, "wt1")
        self.git("worktree", "add", "-b", "feature1", wt_path)

        res = self.run_script("--raw")
        self.assertEqual(res.returncode, 0)
        self.assertIn(f"worktree {self.repo}", res.stdout)
        self.assertIn(f"worktree {wt_path}", res.stdout)

    def test_formatted_report_active_worktrees(self):
        wt_path = os.path.join(self.tmpdir, "wt-active")
        self.git("worktree", "add", "-b", "feature-active", wt_path)

        res = self.run_script()
        self.assertEqual(res.returncode, 0)
        self.assertIn("# Worktrees", res.stdout)
        self.assertIn("## Active Worktrees", res.stdout)
        self.assertIn(self.repo, res.stdout)
        self.assertIn(wt_path, res.stdout)
        self.assertIn("## Stale Worktrees", res.stdout)
        self.assertIn("None detected.", res.stdout)

    def test_stale_worktree_detection(self):
        wt_path = os.path.join(self.tmpdir, "wt-stale")
        self.git("worktree", "add", "-b", "feature-stale", wt_path)

        # Delete directory to mark worktree prunable/stale
        shutil.rmtree(wt_path)

        res = self.run_script()
        self.assertEqual(res.returncode, 0)
        self.assertIn("## Stale Worktrees", res.stdout)
        self.assertIn(wt_path, res.stdout)

    def test_non_destructive_by_default(self):
        wt_path = os.path.join(self.tmpdir, "wt-keep")
        self.git("worktree", "add", "-b", "feature-keep", wt_path)

        res = self.run_script()
        self.assertEqual(res.returncode, 0)
        self.assertTrue(os.path.exists(wt_path))

    def test_remove_flag_execution(self):
        wt_path = os.path.join(self.tmpdir, "wt-remove")
        self.git("worktree", "add", "-b", "feature-remove", wt_path)
        self.assertTrue(os.path.exists(wt_path))

        res = self.run_script("--remove", wt_path)
        self.assertEqual(res.returncode, 0)
        self.assertIn(f"## Remove worktree: {wt_path}", res.stdout)
        self.assertFalse(os.path.exists(wt_path))


if __name__ == "__main__":
    unittest.main()
