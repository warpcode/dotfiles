#!/usr/bin/env python3
"""Unit and integration tests for wt_test.sh in git-worktrees skill."""

import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPT_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "wt_test.sh")
)


class TestWtTestScript(unittest.TestCase):
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

    def run_script(self, *args):
        cmd = [SCRIPT_PATH] + list(args)
        res = subprocess.run(
            cmd,
            cwd=self.tmpdir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return res

    def test_help_flag(self):
        res = self.run_script("-h")
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage: wt_test.sh", res.stdout)

        res = self.run_script("--help")
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage: wt_test.sh", res.stdout)

    def test_missing_args(self):
        res = self.run_script()
        self.assertNotEqual(res.returncode, 0)

        res = self.run_script(self.repo)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Missing command", res.stderr)

    def test_nonexistent_directory(self):
        bogus_dir = os.path.join(self.tmpdir, "does_not_exist")
        res = self.run_script(bogus_dir, "echo", "hi")
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Worktree directory does not exist", res.stderr)

    def test_successful_execution(self):
        res = self.run_script(self.repo, "echo", "hello world")
        self.assertEqual(res.returncode, 0)
        self.assertIn("hello world", res.stdout)
        self.assertIn("=== Worktree Execution Summary ===", res.stdout)
        self.assertIn(f"Worktree: {self.repo}", res.stdout)
        self.assertIn(f"Branch:   {self.default_branch}", res.stdout)
        self.assertIn("Status:   SUCCESS (exit code 0)", res.stdout)

    def test_failed_execution_propagates_exit_code(self):
        res = self.run_script(self.repo, "sh", "-c", "exit 42")
        self.assertEqual(res.returncode, 42)
        self.assertIn("=== Worktree Execution Summary ===", res.stdout)
        self.assertIn("Status:   FAILED (exit code 42)", res.stdout)

    def test_execution_runs_in_target_directory(self):
        marker = os.path.join(self.repo, "in_worktree.txt")
        res = self.run_script(self.repo, "touch", "in_worktree.txt")
        self.assertEqual(res.returncode, 0)
        self.assertTrue(os.path.exists(marker))


if __name__ == "__main__":
    unittest.main()
