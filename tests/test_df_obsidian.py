import unittest
import subprocess
import os
import shutil
import tempfile

class TestDfObsidian(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.rules_dir = os.path.join(self.temp_dir, "rules")
        os.makedirs(self.rules_dir, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_profile_load(self):
        zsh_bin = shutil.which("zsh")
        if not zsh_bin:
            self.skipTest("zsh is not installed")

        script = f"""
        source dot_local/bin/executable_df.obsidian
        _profile_load "{self.rules_dir}" "default.json"
        """
        # Create a mock structure for testing
        with open(os.path.join(self.rules_dir, "default.json"), "w") as f:
            f.write('{"fields": {"a": 1}}')

        # Test basic success
        res = subprocess.run(
            [zsh_bin, "-c", script],
            capture_output=True,
            text=True
        )
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}\nStdout: {res.stdout}")
        self.assertIn('"a":1', res.stdout.replace(' ', ''))

    def test_profile_load_merge(self):
        zsh_bin = shutil.which("zsh")
        if not zsh_bin:
            self.skipTest("zsh is not installed")

        script = f"""
        export DOTFILES_PROFILE=my-profile
        source dot_local/bin/executable_df.obsidian
        _profile_load "{self.rules_dir}" "default.json"
        """
        os.makedirs(os.path.join(self.rules_dir, "my-profile"), exist_ok=True)
        with open(os.path.join(self.rules_dir, "default.json"), "w") as f:
            f.write('{"fields": {"a": 1, "b": 2}}')
        with open(os.path.join(self.rules_dir, "my-profile", "default.json"), "w") as f:
            f.write('{"fields": {"b": 3, "c": 4}}')

        res = subprocess.run(
            [zsh_bin, "-c", script],
            capture_output=True,
            text=True
        )
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}\nStdout: {res.stdout}")
        self.assertIn('"a":1', res.stdout.replace(' ', ''))
        self.assertIn('"b":3', res.stdout.replace(' ', ''))
        self.assertIn('"c":4', res.stdout.replace(' ', ''))

if __name__ == '__main__':
    unittest.main()
