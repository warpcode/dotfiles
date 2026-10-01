"""Tests for dot_zsh/functions/registry.zsh security and functionality."""

import os
import shutil
import subprocess
import tempfile
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class TestRegistrySecurity(unittest.TestCase):
    """Test dot_zsh/functions/registry.zsh against subshell execution and parameter injection."""

    def test_registry_no_eval_or_parameter_expansion_injection(self):
        """Verify registry functions do not evaluate shell code injected in array keys, values, or IDs."""
        script_path = os.path.join(REPO_ROOT, "dot_zsh", "functions", "registry.zsh")
        zsh_bin = shutil.which("zsh")
        if not zsh_bin:
            self.skipTest("zsh executable not found on PATH")

        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            marker_file = tmp.name
        os.remove(marker_file)
        self.addCleanup(lambda: os.path.exists(marker_file) and os.remove(marker_file))

        # Test script passes injection payload strictly via environment variables ($INJECT_KEY, $INJECT_VAL, $INJECT_ID)
        test_zsh_script = """
        source "$SCRIPT_PATH"
        registry.define "test_ns" "$INJECT_ID" "$INJECT_KEY=$INJECT_VAL"
        registry.get "test_ns" "$INJECT_ID" "$INJECT_KEY"
        registry.exists "test_ns" "$INJECT_ID"
        """

        env = dict(os.environ)
        env["SCRIPT_PATH"] = script_path
        env["INJECT_ID"] = f"id_$(touch {marker_file})"
        env["INJECT_KEY"] = f"key]$(touch {marker_file})"
        env["INJECT_VAL"] = f"val]$(touch {marker_file})"

        res = subprocess.run([zsh_bin, "-c", test_zsh_script], capture_output=True, text=True, env=env)
        self.assertEqual(res.returncode, 0, f"zsh script failed unexpectedly: stderr={res.stderr}")
        self.assertFalse(os.path.exists(marker_file), "Security vulnerability: injected shell command was executed!")


if __name__ == "__main__":
    unittest.main()
