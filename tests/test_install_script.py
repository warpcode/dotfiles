import os
import re
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALL_SH_PATH = os.path.join(REPO_ROOT, "install.sh")


class TestInstallScriptSecurity(unittest.TestCase):
    """Tests to verify security properties of install.sh."""

    def test_no_curl_pipe_to_shell(self):
        """Ensure install.sh does not pipe curl downloads directly into shell interpreters."""
        with open(INSTALL_SH_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        # Check for unverified piped execution patterns like `curl ... | sh` or `curl ... | bash`
        curl_pipe_pattern = re.compile(r"curl\s+.*?\|\s*(?:ba)?sh")
        matches = curl_pipe_pattern.findall(content)
        self.assertEqual(
            matches,
            [],
            f"Found unverified curl pipe to shell pattern in install.sh: {matches}",
        )

    def test_installer_script_download_uses_mktemp(self):
        """Ensure script downloads for external tools (Homebrew, chezmoi, mise) download to temporary files."""
        with open(INSTALL_SH_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("mktemp -t homebrew-bootstrap-XXXXXX.sh", content)
        self.assertIn("mktemp -t chezmoi-bootstrap-XXXXXX.sh", content)
        self.assertIn("mktemp -t mise-bootstrap-XXXXXX.sh", content)


if __name__ == "__main__":
    unittest.main()
