import subprocess
import unittest
from pathlib import Path

class TestPRSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_shell_script(self):
        script_path = Path(__file__).parent / "test_pr_sync_validate.sh"
        res = subprocess.run(["bash", str(script_path)], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Shell test failed with output:\n{res.stdout}\n{res.stderr}")

if __name__ == "__main__":
    unittest.main()
