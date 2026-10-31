"""Unit test wrapper for pr_sync_validate test script."""

import os
import subprocess
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "test_pr_sync_validate.sh")
)


class TestPrSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_script(self):
        res = subprocess.run(
            ["bash", SCRIPT],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.assertEqual(res.returncode, 0, f"Script failed with output:\n{res.stdout}\n{res.stderr}")


if __name__ == "__main__":
    unittest.main()
