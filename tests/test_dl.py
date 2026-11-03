import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestDlScript(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.dl_script = str(self.repo_root / "dot_local" / "bin" / "executable_dl")
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_url_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.dl_script],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_empty_string_url_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.dl_script, ""],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_invokes_wget_with_double_dash_and_safe_output(self):
        # Create a mock wget script in PATH to inspect the exact arguments passed
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()
        mock_wget = mock_bin_dir / "wget"
        mock_wget.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$@\" > wget_args.txt\n"
        )
        mock_wget.chmod(0o755)

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"

        target_url = "https://example.com/path/my%20test%20file.tar.gz?query=1#frag"
        res = subprocess.run(
            ["bash", self.dl_script, target_url],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        args_file = Path(self.test_dir) / "wget_args.txt"
        self.assertTrue(args_file.exists())
        args = args_file.read_text().splitlines()

        # Check that -O was given the decoded basename without query parameters
        self.assertIn("-O", args)
        idx_o = args.index("-O")
        self.assertEqual(args[idx_o + 1], "my test file.tar.gz")

        # Check that '--' was passed before the target URL
        self.assertIn("--", args)
        idx_dashdash = args.index("--")
        self.assertEqual(args[idx_dashdash + 1], target_url)

    def test_custom_saveto_argument_is_respected(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()
        mock_wget = mock_bin_dir / "wget"
        mock_wget.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$@\" > wget_args.txt\n"
        )
        mock_wget.chmod(0o755)

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"

        res = subprocess.run(
            ["bash", self.dl_script, "https://example.com/foo.zip", "custom_name.zip"],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        args_file = Path(self.test_dir) / "wget_args.txt"
        self.assertTrue(args_file.exists())
        args = args_file.read_text().splitlines()

        idx_o = args.index("-O")
        self.assertEqual(args[idx_o + 1], "custom_name.zip")
        self.assertIn("--", args)

    def test_url_with_flag_injection_prevented(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()
        mock_wget = mock_bin_dir / "wget"
        mock_wget.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$@\" > wget_args.txt\n"
        )
        mock_wget.chmod(0o755)

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"

        malicious_url = "--post-file=/etc/passwd"
        res = subprocess.run(
            ["bash", self.dl_script, malicious_url],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        args_file = Path(self.test_dir) / "wget_args.txt"
        self.assertTrue(args_file.exists())
        args = args_file.read_text().splitlines()

        # Malicious URL must appear strictly after '--' delimiter
        idx_dashdash = args.index("--")
        self.assertIn(malicious_url, args[idx_dashdash + 1:])


if __name__ == "__main__":
    unittest.main()
