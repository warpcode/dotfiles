#!/usr/bin/env python3
"""Unit test wrapper for test_pr_sync_validate.sh in github-pr skill."""

import os
import subprocess
import unittest

SCRIPT_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "test_pr_sync_validate.sh")
)


class TestPrSyncValidate(unittest.TestCase):
    def test_pr_sync_validate(self):
        res = subprocess.run(
            ["bash", SCRIPT_PATH],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            res.returncode,
            0,
            f"test_pr_sync_validate.sh failed with code {res.returncode}:\n{res.stdout}\n{res.stderr}",
        )


if __name__ == "__main__":
    unittest.main()
