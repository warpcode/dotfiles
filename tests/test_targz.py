import os
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path


class TestTargzScript(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.script_path = str(self.repo_root / "dot_local" / "bin" / "executable_targz")
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_argument_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_empty_string_argument_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path, ""],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Usage:", res.stderr)

    def test_nonexistent_source_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path, "does_not_exist_file"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("does not exist", res.stderr)

    def test_compresses_regular_file(self):
        sample_file = Path(self.test_dir) / "sample.txt"
        sample_file.write_text("hello targz compression test")

        res = subprocess.run(
            ["bash", self.script_path, "sample.txt"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        self.assertIn("created successfully", res.stdout)

        archive_path = Path(self.test_dir) / "sample.txt.tar.gz"
        self.assertTrue(archive_path.exists())

        # Verify tar.gz contents
        with tarfile.open(archive_path, "r:gz") as tar:
            names = tar.getnames()
            self.assertIn("sample.txt", names)

    def test_compresses_directory(self):
        sample_dir = Path(self.test_dir) / "sample_dir"
        sample_dir.mkdir()
        (sample_dir / "file1.txt").write_text("file one")
        (sample_dir / "file2.txt").write_text("file two")

        res = subprocess.run(
            ["bash", self.script_path, "sample_dir/"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        self.assertIn("created successfully", res.stdout)

        archive_path = Path(self.test_dir) / "sample_dir.tar.gz"
        self.assertTrue(archive_path.exists())

        with tarfile.open(archive_path, "r:gz") as tar:
            names = tar.getnames()
            self.assertTrue(any("file1.txt" in n for n in names))

    def test_source_starting_with_dash_does_not_cause_option_injection(self):
        # A file whose name starts with dash e.g. -v or -h
        dash_file = Path(self.test_dir) / "-testfile"
        dash_file.write_text("content in dash file")

        res = subprocess.run(
            ["bash", self.script_path, "-testfile"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        archive_path = Path(self.test_dir) / "-testfile.tar.gz"
        self.assertTrue(archive_path.exists())

        with tarfile.open(archive_path, "r:gz") as tar:
            names = tar.getnames()
            self.assertIn("-testfile", names)


if __name__ == "__main__":
    unittest.main()
