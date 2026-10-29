import os
import subprocess
import unittest

class TestPrSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_script(self):
        test_script = os.path.join(os.path.dirname(__file__), "test_pr_sync_validate.sh")
        result = subprocess.run(["bash", test_script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, f"Script failed with output:\n{result.stdout}\n{result.stderr}")

if __name__ == "__main__":
    unittest.main()
