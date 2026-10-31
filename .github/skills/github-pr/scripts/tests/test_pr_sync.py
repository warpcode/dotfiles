#!/usr/bin/env python3
"""test_pr_sync.py - Python unit test wrapper for github-pr shell tests."""

import os
import subprocess
import unittest


class TestPRSync(unittest.TestCase):
    def test_pr_sync_validate_sh(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        script_path = os.path.join(tests_dir, "test_pr_sync_validate.sh")
        if not os.path.exists(script_path):
            self.skipTest("test_pr_sync_validate.sh not found")

        res = subprocess.run(["bash", script_path], capture_output=True, text=True)
        self.assertEqual(
            res.returncode,
            0,
            f"test_pr_sync_validate.sh failed with return code {res.returncode}:\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}",
        )


if __name__ == "__main__":
    unittest.main()
