"""Unit tests for install.sh script and integrity verification logic."""

import hashlib
import os
import subprocess
import tempfile
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALL_SH = os.path.join(REPO_ROOT, "install.sh")


class TestInstallShChecksumVerification(unittest.TestCase):
    """Test verify_checksum shell function in install.sh."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.test_file = os.path.join(self.temp_dir, "sample.sh")
        self.content = b"#!/bin/sh\necho 'hello world'\n"
        with open(self.test_file, "wb") as f:
            f.write(self.content)
        self.expected_hash = hashlib.sha256(self.content).hexdigest()

    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _run_verify_checksum(self, filepath, *expected_hashes):
        """Helper to invoke verify_checksum function within bash session sourcing install.sh."""
        hashes_str = " ".join(f'"{h}"' for h in expected_hashes)
        cmd = f'source "{INSTALL_SH}" && verify_checksum "{filepath}" {hashes_str}'
        res = subprocess.run(
            ["bash", "-c", cmd],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        return res

    def test_verify_checksum_valid(self):
        res = self._run_verify_checksum(self.test_file, self.expected_hash)
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}")

    def test_verify_checksum_valid_uppercase(self):
        res = self._run_verify_checksum(self.test_file, self.expected_hash.upper())
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}")

    def test_verify_checksum_multiple_hashes_one_matching(self):
        dummy_hash = "0" * 64
        res = self._run_verify_checksum(self.test_file, dummy_hash, self.expected_hash)
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}")

    def test_verify_checksum_invalid(self):
        bad_hash = "a" * 64
        res = self._run_verify_checksum(self.test_file, bad_hash)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Integrity check failed", res.stderr)
        self.assertIn(self.expected_hash, res.stderr)

    def test_verify_checksum_nonexistent_file(self):
        non_existent = os.path.join(self.temp_dir, "does_not_exist.sh")
        res = self._run_verify_checksum(non_existent, self.expected_hash)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("file does not exist", res.stderr)


if __name__ == "__main__":
    unittest.main()
