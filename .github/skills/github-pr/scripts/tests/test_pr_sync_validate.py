import unittest
import subprocess
import os

class TestPRSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_script(self):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        sh_script = os.path.join(script_dir, "test_pr_sync_validate.sh")
        res = subprocess.run(["bash", sh_script], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"test_pr_sync_validate.sh failed with output:\n{res.stdout}\n{res.stderr}")

if __name__ == "__main__":
    unittest.main()
