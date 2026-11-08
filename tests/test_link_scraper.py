import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestLinkScraperScript(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.scraper_script = str(self.repo_root / "dot_local" / "bin" / "executable_link-scraper")
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_url_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.scraper_script],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_empty_string_url_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.scraper_script, ""],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_invokes_lynx_with_double_dash_delimiter(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()
        mock_lynx = mock_bin_dir / "lynx"
        mock_lynx.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$@\" > lynx_args.txt\n"
            "echo '   1. http://example.com/target'\n"
        )
        mock_lynx.chmod(0o755)

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"

        target_url = "https://example.com/page"
        res = subprocess.run(
            ["bash", self.scraper_script, target_url],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "http://example.com/target")

        args_file = Path(self.test_dir) / "lynx_args.txt"
        self.assertTrue(args_file.exists())
        args = args_file.read_text().splitlines()

        self.assertIn("-dump", args)
        self.assertIn("-hiddenlinks=listonly", args)
        self.assertIn("--", args)
        idx_dashdash = args.index("--")
        self.assertEqual(args[idx_dashdash + 1], target_url)

    def test_option_injection_prevented(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()
        mock_lynx = mock_bin_dir / "lynx"
        mock_lynx.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$@\" > lynx_args.txt\n"
        )
        mock_lynx.chmod(0o755)

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"

        malicious_arg = "-auth=user:pass"
        res = subprocess.run(
            ["bash", self.scraper_script, malicious_arg],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)

        args_file = Path(self.test_dir) / "lynx_args.txt"
        self.assertTrue(args_file.exists())
        args = args_file.read_text().splitlines()

        idx_dashdash = args.index("--")
        self.assertIn(malicious_arg, args[idx_dashdash + 1:])

    def test_extracts_multiple_links_with_varying_whitespace(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()
        mock_lynx = mock_bin_dir / "lynx"
        mock_lynx.write_text(
            "#!/usr/bin/env bash\n"
            "echo '   1. http://example.com/one'\n"
            "echo ''\n"
            "echo '  10. https://example.org/two'\n"
            "echo ' 100.  http://example.net/three?a=1&b=2'\n"
            "echo ' 101.  http://example.org/file name with spaces.pdf'\n"
            "echo ' 102.  http://example.org/doc#section with fragment'\n"
        )
        mock_lynx.chmod(0o755)

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"

        res = subprocess.run(
            ["bash", self.scraper_script, "https://example.com"],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0)
        expected = [
            "http://example.com/one",
            "https://example.org/two",
            "http://example.net/three?a=1&b=2",
            "http://example.org/file name with spaces.pdf",
            "http://example.org/doc#section with fragment",
        ]
        self.assertEqual(res.stdout.splitlines(), expected)


if __name__ == "__main__":
    unittest.main()
