import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestTs2DateScript(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.ts2date_script = str(self.repo_root / "dot_local" / "bin" / "executable_ts2date")
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_timestamp_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.ts2date_script],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_empty_string_timestamp_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.ts2date_script, ""],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_whitespace_only_timestamp_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.ts2date_script, "   "],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_valid_integer_positional_argument(self):
        res = subprocess.run(
            ["bash", self.ts2date_script, "1700000000"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertTrue(res.stdout.strip().startswith("2023-11-14"))

    def test_valid_piped_standard_input(self):
        res = subprocess.run(
            ["bash", self.ts2date_script],
            input="1700000000\n",
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertTrue(res.stdout.strip().startswith("2023-11-14"))

    def test_negative_timestamp(self):
        # Explicitly set TZ=UTC to isolate timezone offset across test environments
        env = {**os.environ, "TZ": "UTC"}
        res = subprocess.run(
            ["bash", self.ts2date_script, "-1000"],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertTrue(res.stdout.strip().startswith("1969-12-31"))

    def test_float_timestamp(self):
        res = subprocess.run(
            ["bash", self.ts2date_script, "1700000000.123"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertTrue(res.stdout.strip().startswith("2023-11-14"))

    def test_option_injection_prevented(self):
        for malicious_input in ["-f", "--reference=/etc/passwd", "-d", "-u", "; rm -rf /"]:
            res = subprocess.run(
                ["bash", self.ts2date_script, malicious_input],
                cwd=self.test_dir,
                capture_output=True,
                text=True,
            )
            self.assertEqual(res.returncode, 1, f"Failed to reject malicious input: {malicious_input}")
            self.assertIn("ts2date: invalid timestamp", res.stderr)


if __name__ == "__main__":
    unittest.main()
