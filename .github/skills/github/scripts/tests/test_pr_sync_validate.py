import os
import subprocess
import unittest


class TestPRSyncValidate(unittest.TestCase):
    def test_pr_sync_validate_sh(self):
        test_dir = os.path.dirname(__file__)
        sh_script = os.path.join(test_dir, "test_pr_sync_validate.sh")
        res = subprocess.run(["bash", sh_script], capture_output=True, text=True)
        self.assertEqual(
            res.returncode,
            0,
            f"test_pr_sync_validate.sh failed with stdout:\n{res.stdout}\nstderr:\n{res.stderr}",
        )


if __name__ == "__main__":
    unittest.main()
