import unittest
import re
from pathlib import Path

class TestInstallShSecurity(unittest.TestCase):
    def setUp(self):
        self.install_sh_path = Path(__file__).parent.parent / "install.sh"
        self.content = self.install_sh_path.read_text()

    def test_no_unverified_curl_pipe_to_shell(self):
        # Check for unverified curl piping patterns like `curl ... | sh` or `curl ... | bash`
        unverified_pipe_pattern = re.compile(r"curl\s+[^|\n]+\|\s*(sh|bash|zsh)")
        matches = unverified_pipe_pattern.findall(self.content)

        self.assertEqual(
            len(matches),
            0,
            f"Found unverified curl pipe to shell in install.sh: {matches}"
        )

    def test_download_verification_and_execution_handling(self):
        # Verify temporary file usage with non-empty check (-s)
        self.assertIn("mktemp -t mise-bootstrap-XXXXXX.sh", self.content)
        self.assertIn("[[ -s \"${mise_install_script}\" ]]", self.content)

        # Verify error handling on script execution failure
        self.assertIn("if ! sh \"${mise_install_script}\"; then", self.content)

if __name__ == "__main__":
    unittest.main()
