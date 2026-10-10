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
        self.default_branch = self.git("branch", "--show-current", cwd=self.repo).strip()

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
        self.assertIn(f"  - {wt_path}", res.stdout)
        self.assertNotIn("None detected.", res.stdout)

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

    def test_create_clean_merge(self):
        self.git("checkout", "-b", "feature-clean", cwd=self.repo)
        fpath = os.path.join(self.repo, "clean.txt")
        with open(fpath, "w") as f:
            f.write("clean\n")
        self.git("add", "clean.txt", cwd=self.repo)
        self.git("commit", "-m", "Clean feature", cwd=self.repo)
        self.git("checkout", self.default_branch, cwd=self.repo)

        wt_path = os.path.join(self.tmpdir, "wt-created-clean")
        res = self.run_script(
            "--create", "feature-clean",
            "--base", self.default_branch,
            "--path", wt_path,
            "--no-fetch",
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("# Worktree Created: Success", res.stdout)
        self.assertTrue(os.path.exists(wt_path))
        self.assertTrue(os.path.exists(os.path.join(wt_path, "clean.txt")))

    def test_create_conflict_detection(self):
        self.git("checkout", "-b", "feature-conflict", cwd=self.repo)
        readme = os.path.join(self.repo, "README.md")
        with open(readme, "w") as f:
            f.write("# Feature Edit\n")
        self.git("add", "README.md", cwd=self.repo)
        self.git("commit", "-m", "Feature readme", cwd=self.repo)
        self.git("checkout", self.default_branch, cwd=self.repo)

        with open(readme, "w") as f:
            f.write("# Master Edit\n")
        self.git("add", "README.md", cwd=self.repo)
        self.git("commit", "-m", "Master readme", cwd=self.repo)

        wt_path = os.path.join(self.tmpdir, "wt-created-conflict")
        res = self.run_script(
            "--create", "feature-conflict",
            "--base", self.default_branch,
            "--path", wt_path,
            "--no-fetch",
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("# Worktree Created: Conflict Detected", res.stdout)
        self.assertIn("README.md", res.stdout)


if __name__ == "__main__":
    unittest.main()
