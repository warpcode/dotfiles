import os
import subprocess
import tempfile
import unittest

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PUSH_SH = os.path.join(SCRIPTS_DIR, "push.sh")
SYNC_SH = os.path.join(SCRIPTS_DIR, "sync.sh")


class TestPushSyncScripts(unittest.TestCase):
    def test_push_help(self):
        res = subprocess.run([PUSH_SH, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage:", res.stdout)
        self.assertIn("--dry-run", res.stdout)

    def test_sync_help(self):
        res = subprocess.run([SYNC_SH, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage:", res.stdout)
        self.assertIn("--dry-run", res.stdout)

    def test_push_dry_run(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Initialize a git repo with a branch in tmpdir so push.sh --dry-run succeeds regardless of detached HEAD state in CI
            subprocess.run(["git", "init", "-b", "main", tmpdir], capture_output=True, check=True)
            subprocess.run(["git", "-C", tmpdir, "config", "user.name", "Test"], capture_output=True, check=True)
            subprocess.run(["git", "-C", tmpdir, "config", "user.email", "test@example.com"], capture_output=True, check=True)
            subprocess.run(["git", "-C", tmpdir, "commit", "--allow-empty", "-m", "init"], capture_output=True, check=True)
            res = subprocess.run([PUSH_SH, "--dry-run"], cwd=tmpdir, capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            self.assertIn("Git Push (Dry Run)", res.stdout)


if __name__ == "__main__":
    unittest.main()
