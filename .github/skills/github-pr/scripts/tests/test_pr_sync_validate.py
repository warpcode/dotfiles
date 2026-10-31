"""Unit test wrapper for github-pr skill test_pr_sync_validate.sh."""

import os
import subprocess
import unittest
from pathlib import Path


class TestPrSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_script(self):
        script_dir = Path(__file__).resolve().parent
        sh_test = script_dir / "test_pr_sync_validate.sh"
        self.assertTrue(sh_test.is_file(), f"{sh_test} not found")
        res = subprocess.run(["bash", str(sh_test)], capture_output=True, text=True)
        self.assertEqual(
            res.returncode,
            0,
            f"test_pr_sync_validate.sh failed with return code {res.returncode}:\nStdout:\n{res.stdout}\nStderr:\n{res.stderr}",
        )


if __name__ == "__main__":
    unittest.main()
