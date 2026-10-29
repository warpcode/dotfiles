import subprocess
import unittest
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent


class TestPRSyncValidateScript(unittest.TestCase):

    def test_pr_sync_validate_sh(self):
        script_path = TESTS_DIR / "test_pr_sync_validate.sh"
        res = subprocess.run(["bash", str(script_path)], capture_output=True, text=True)
        self.assertEqual(
            res.returncode,
            0,
            f"test_pr_sync_validate.sh failed:\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}"
        )


if __name__ == "__main__":
    unittest.main()
