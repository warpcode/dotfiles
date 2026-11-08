cat << 'INNER_EOF' > tests/test_df_obsidian.py
import unittest
import subprocess
import os
import shutil

class TestDfObsidian(unittest.TestCase):
    def test_profile_load(self):
        zsh_bin = shutil.which("zsh")
        if not zsh_bin:
            self.skipTest("zsh is not installed")

        script = """
        source dot_local/bin/executable_df.obsidian
        _profile_load "/tmp/test_df_obsidian/rules" "default.json"
        """
        # Create a mock structure for testing
        os.makedirs("/tmp/test_df_obsidian/rules", exist_ok=True)
        with open("/tmp/test_df_obsidian/rules/default.json", "w") as f:
            f.write('{"fields": {"a": 1}}')

        # Test basic success
        res = subprocess.run(
            [zsh_bin, "-c", script],
            capture_output=True,
            text=True
        )
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn('"a":1', res.stdout.replace(' ', ''))

    def test_profile_load_merge(self):
        zsh_bin = shutil.which("zsh")
        if not zsh_bin:
            self.skipTest("zsh is not installed")

        script = """
        export DOTFILES_PROFILE=my-profile
        source dot_local/bin/executable_df.obsidian
        _profile_load "/tmp/test_df_obsidian/rules" "default.json"
        """
        os.makedirs("/tmp/test_df_obsidian/rules/my-profile", exist_ok=True)
        with open("/tmp/test_df_obsidian/rules/default.json", "w") as f:
            f.write('{"fields": {"a": 1, "b": 2}}')
        with open("/tmp/test_df_obsidian/rules/my-profile/default.json", "w") as f:
            f.write('{"fields": {"b": 3, "c": 4}}')

        res = subprocess.run(
            [zsh_bin, "-c", script],
            capture_output=True,
            text=True
        )
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn('"a":1', res.stdout.replace(' ', ''))
        self.assertIn('"b":3', res.stdout.replace(' ', ''))
        self.assertIn('"c":4', res.stdout.replace(' ', ''))

if __name__ == '__main__':
    unittest.main()
INNER_EOF
