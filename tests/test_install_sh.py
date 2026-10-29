import hashlib
import os
import subprocess
import tempfile
import unittest
import re
from pathlib import Path

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALL_SH = os.path.join(REPO_ROOT, "install.sh")

class TestInstallShChecksumVerification(unittest.TestCase):
    """Test verify_checksum shell function in install.sh."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.test_file = os.path.join(self.temp_dir, "sample.sh")
        self.content = b"#!/bin/sh\necho 'hello world'\n"
        with open(self.test_file, "wb") as f:
            f.write(self.content)
        self.expected_hash = hashlib.sha256(self.content).hexdigest()

    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _run_verify_checksum(self, filepath, *expected_hashes):
        """Helper to invoke verify_checksum function within bash session sourcing install.sh."""
        hashes_str = " ".join(f'"{h}"' for h in expected_hashes)
        cmd = f'source "{INSTALL_SH}" && verify_checksum "{filepath}" {hashes_str}'
        res = subprocess.run(
            ["bash", "-c", cmd],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        return res

    def test_verify_checksum_valid(self):
        res = self._run_verify_checksum(self.test_file, self.expected_hash)
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}")

    def test_verify_checksum_valid_uppercase(self):
        res = self._run_verify_checksum(self.test_file, self.expected_hash.upper())
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}")

    def test_verify_checksum_multiple_hashes_one_matching(self):
        dummy_hash = "0" * 64
        res = self._run_verify_checksum(self.test_file, dummy_hash, self.expected_hash)
        self.assertEqual(res.returncode, 0, msg=f"Stderr: {res.stderr}")

    def test_verify_checksum_invalid(self):
        bad_hash = "a" * 64
        res = self._run_verify_checksum(self.test_file, bad_hash)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Integrity check failed", res.stderr)
        self.assertIn(self.expected_hash, res.stderr)

    def test_verify_checksum_nonexistent_file(self):
        non_existent = os.path.join(self.temp_dir, "does_not_exist.sh")
        res = self._run_verify_checksum(non_existent, self.expected_hash)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("file does not exist", res.stderr)

    def test_verify_checksum_no_tool(self):
        """Test fallback exhaust when no SHA-256 tool is available."""
        import shutil
        # Resolve bash binary before altering PATH
        bash_bin = shutil.which("bash")
        self.assertIsNotNone(bash_bin, "Failed to resolve bash binary")

        hashes_str = f'"{self.expected_hash}"'
        cmd = f'source "{INSTALL_SH}" && verify_checksum "{self.test_file}" {hashes_str}'

        # Run with empty PATH to simulate missing sha256sum, shasum, and openssl
        env = os.environ.copy()
        env["PATH"] = "/nonexistent"
        if "HOME" not in env:
            env["HOME"] = "/tmp"

        res = subprocess.run(
            [bash_bin, "-c", cmd],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            env=env
        )

        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Checksum verification failed: no SHA-256 tool available", res.stderr)

class TestInstallShDetectOS(unittest.TestCase):
    """Test detect_os and detect_linux_os_id shell functions in install.sh."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _run_detect_os(self, ostype, termux_version=None, prefix=None, os_release_content=None):
        env = os.environ.copy()
        env["OSTYPE"] = ostype
        if termux_version is not None:
            env["TERMUX_VERSION"] = termux_version
        else:
            env.pop("TERMUX_VERSION", None)

        os_release_path = os.path.join(self.temp_dir, "os-release")
        if os_release_content is not None:
            with open(os_release_path, "w") as f:
                f.write(os_release_content)

        if prefix is not None:
            env["PREFIX"] = prefix
        else:
            env.pop("PREFIX", None)

        # We override /etc/os-release in detect_linux_os_id by overriding the file lookup if os_release_content provided
        # or we test running bash with fake /etc/os-release via redirection or mock function if needed.
        # To easily test os-release parsing cleanly, we can sed/replace /etc/os-release or define helper inline in test command.
        if os_release_content is not None:
            cmd = f'source "{INSTALL_SH}" && detect_linux_os_id() {{ local os_id="linux"; if [[ -f "{os_release_path}" ]]; then os_id="$(grep -E \'^ID=\' "{os_release_path}" 2>/dev/null | cut -d= -f2 | tr -d \'"\' || echo "linux")"; fi; case "${{os_id}}" in ubuntu|debian) echo "debian" ;; fedora|arch) echo "${{os_id}}" ;; *) echo "linux" ;; esac; }} && detect_os'
        else:
            cmd = f'source "{INSTALL_SH}" && detect_os'

        res = subprocess.run(
            ["bash", "-c", cmd],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            env=env,
        )
        return res

    def test_detect_os_macos(self):
        res = self._run_detect_os("darwin20.0")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "macos")

    def test_detect_os_termux(self):
        prefix_dir = os.path.join(self.temp_dir, "usr")
        os.makedirs(prefix_dir, exist_ok=True)
        res = self._run_detect_os("linux-gnu", termux_version="0.118", prefix=prefix_dir)
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "termux")

    def test_detect_os_ubuntu(self):
        res = self._run_detect_os("linux-gnu", os_release_content='ID=ubuntu\nNAME="Ubuntu"')
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "debian")

    def test_detect_os_debian(self):
        res = self._run_detect_os("linux-gnu", os_release_content='ID="debian"\n')
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "debian")

    def test_detect_os_fedora(self):
        res = self._run_detect_os("linux-gnu", os_release_content='ID=fedora\n')
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "fedora")

    def test_detect_os_arch(self):
        res = self._run_detect_os("linux-gnu", os_release_content='ID=arch\n')
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "arch")

    def test_detect_os_generic_linux(self):
        res = self._run_detect_os("linux-gnu", os_release_content='ID=alpine\n')
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "linux")

    def test_detect_os_unknown(self):
        res = self._run_detect_os("freebsd12.0")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "unknown")


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

    def test_chezmoi_wiring(self):
        # Verify that chezmoi execution only happens if verify_checksum succeeds
        self.assertIn('if verify_checksum "${chezmoi_install_script}" ${expected_chezmoi_sha256}; then', self.content)
        self.assertIn('if ! sh "${chezmoi_install_script}" -b "${HOME}/.local/bin"; then', self.content)
        self.assertIn('err "Failed integrity check for chezmoi installer"', self.content)

    def test_homebrew_wiring(self):
        # Verify Homebrew installation temporary file usage and integrity check
        self.assertIn("mktemp -t homebrew-bootstrap-XXXXXX.sh", self.content)
        self.assertIn('[[ -s "${brew_install_script}" ]]', self.content)
        self.assertIn('if verify_checksum "${brew_install_script}" ${expected_brew_sha256}; then', self.content)
        self.assertIn('if ! /bin/bash "${brew_install_script}"; then', self.content)
        self.assertIn('err "Failed integrity check for Homebrew installer"', self.content)

    def test_mise_wiring(self):
        # Verify that mise execution only happens if verify_checksum succeeds
        self.assertIn('if verify_checksum "${mise_install_script}" ${expected_mise_sha256}; then', self.content)
        self.assertIn('if ! sh "${mise_install_script}"; then', self.content)
        self.assertIn('err "Failed integrity check for mise installer"', self.content)


if __name__ == "__main__":
    unittest.main()
