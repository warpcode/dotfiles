"""Unit tests for validate.sh script."""

import json
import os
import shutil
import subprocess
import tempfile
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATE_SH = os.path.join(REPO_ROOT, "validate.sh")


class TestValidateShFlags(unittest.TestCase):
    """Test command-line flag handling and basic output of validate.sh."""

    def test_help_flags(self):
        for flag in ["-h", "--help"]:
            with self.subTest(flag=flag):
                res = subprocess.run(
                    [VALIDATE_SH, flag],
                    cwd=REPO_ROOT,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(res.returncode, 0)
                self.assertIn("Local mirror of CI validation", res.stdout)

    def test_unknown_argument(self):
        res = subprocess.run(
            [VALIDATE_SH, "--unknown-flag"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("validate: unknown argument: --unknown-flag", res.stderr)
        self.assertIn("Usage:", res.stdout)

    def test_lint_only_flag(self):
        res = subprocess.run(
            [VALIDATE_SH, "--lint-only"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("SKIP unittest (--lint-only)", res.stdout)
        self.assertIn("all checks passed", res.stdout)

    def test_fast_flag(self):
        res = subprocess.run(
            [VALIDATE_SH, "--fast"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("SKIP unittest (--fast)", res.stdout)
        self.assertIn("all checks passed", res.stdout)

    def test_json_flag(self):
        res = subprocess.run(
            [VALIDATE_SH, "--lint-only", "--json"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        lines = res.stdout.strip().splitlines()
        last_line = lines[-1]
        data = json.loads(last_line)

        self.assertIn("status", data)
        self.assertIn("passed", data)
        self.assertIn("failed", data)
        self.assertIn("failures", data)

        self.assertEqual(data["status"], 0)
        self.assertGreater(data["passed"], 0)
        self.assertEqual(data["failed"], 0)
        self.assertEqual(data["failures"], [])


class TestValidateShFailureModes(unittest.TestCase):
    """Test validate.sh execution and error detection under failure conditions in an isolated repo."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        # Initialize temp directory as a git repository
        subprocess.run(["git", "init"], cwd=self.temp_dir, capture_output=True, check=True)
        # Copy validate.sh to the temp repo
        self.temp_validate = os.path.join(self.temp_dir, "validate.sh")
        shutil.copy2(VALIDATE_SH, self.temp_validate)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_bash_syntax_error_failure(self):
        bad_sh = os.path.join(self.temp_dir, "broken.sh")
        with open(bad_sh, "w") as f:
            f.write("if then invalid syntax")

        res = subprocess.run(
            [self.temp_validate, "--lint-only", "--json"],
            cwd=self.temp_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        lines = res.stdout.strip().splitlines()
        last_line = lines[-1]
        data = json.loads(last_line)

        self.assertEqual(data["status"], 1)
        self.assertGreater(data["failed"], 0)
        self.assertTrue(any("bash -n (syntax)" in f for f in data["failures"]))

    def test_stray_artifacts_failure(self):
        stray_file = os.path.join(self.temp_dir, "patch.rej")
        with open(stray_file, "w") as f:
            f.write("stray reject file")

        # Track the stray file in git so git ls-files detects it
        subprocess.run(["git", "add", "patch.rej"], cwd=self.temp_dir, capture_output=True, check=True)

        res = subprocess.run(
            [self.temp_validate, "--lint-only", "--json"],
            cwd=self.temp_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        lines = res.stdout.strip().splitlines()
        last_line = lines[-1]
        data = json.loads(last_line)

        self.assertEqual(data["status"], 1)
        self.assertTrue(any("stray-artifacts" in f for f in data["failures"]))


if __name__ == "__main__":
    unittest.main()
