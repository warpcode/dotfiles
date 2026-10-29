import os
import subprocess
import unittest

class TestPRSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_script(self):
        script_path = os.path.join(os.path.dirname(__file__), "test_pr_sync_validate.sh")
        proc = subprocess.run(["bash", script_path], capture_output=True, text=True)
        self.assertEqual(
            proc.returncode, 0,
            f"test_pr_sync_validate.sh failed with returncode {proc.returncode}.\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
        )

if __name__ == "__main__":
    unittest.main()
