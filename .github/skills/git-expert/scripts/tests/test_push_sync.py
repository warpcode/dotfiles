import os
import subprocess
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
        res = subprocess.run([PUSH_SH, "--dry-run"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("Git Push (Dry Run)", res.stdout)


if __name__ == "__main__":
    unittest.main()
