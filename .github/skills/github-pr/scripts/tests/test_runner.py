import os
import subprocess
import unittest

class TestPRSyncValidateShellScripts(unittest.TestCase):
    def test_run_shell_tests(self):
        tests_dir = os.path.dirname(__file__)
        for fname in os.listdir(tests_dir):
            if fname.startswith("test_") and fname.endswith(".sh"):
                filepath = os.path.join(tests_dir, fname)
                res = subprocess.run(["bash", filepath], capture_output=True, text=True)
                self.assertEqual(
                    res.returncode,
                    0,
                    f"Shell test {fname} failed with output:\n{res.stdout}\n{res.stderr}",
                )

if __name__ == "__main__":
    unittest.main()
