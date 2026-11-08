import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestPhrasegenScript(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.script_path = str(self.repo_root / "dot_local" / "bin" / "executable_phrasegen")
        self.test_dir = tempfile.mkdtemp()
        self.wordlist_dir = Path(self.test_dir) / "dotfiles" / "wordlists"
        self.wordlist_dir.mkdir(parents=True)
        # Create a sample wordlist file
        self.wordlist_file = self.wordlist_dir / "google-10000-english-usa-no-swears-test.txt"
        words = ["apple", "banana", "cherry", "date", "elderberry", "fig", "grape"]
        self.wordlist_file.write_text("\n".join(words) + "\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def _run_phrasegen(self, args=None, env_extra=None):
        env = {**os.environ, "XDG_CONFIG_HOME": self.test_dir}
        if env_extra:
            env.update(env_extra)
        cmd = ["bash", self.script_path]
        if args:
            cmd.extend(args)
        return subprocess.run(
            cmd,
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )

    def test_default_invocation(self):
        res = self._run_phrasegen()
        self.assertEqual(res.returncode, 0, msg=f"stderr: {res.stderr}")
        generated = res.stdout.strip().split(" ")
        self.assertEqual(len(generated), 4)

    def test_custom_word_count_and_delimiter(self):
        res = self._run_phrasegen(["2", "-"])
        self.assertEqual(res.returncode, 0, msg=f"stderr: {res.stderr}")
        generated = res.stdout.strip().split("-")
        self.assertEqual(len(generated), 2)

    def test_invalid_word_count_rejected(self):
        for bad_count in ["0", "-1", "abc", "4.5", "1001", ""]:
            res = self._run_phrasegen([bad_count])
            self.assertEqual(res.returncode, 1, f"Failed to reject invalid count: {bad_count}")
            self.assertIn("Usage: phrasegen [words (1-1000)]", res.stderr)

    def test_option_injection_in_words_rejected(self):
        for flag in ["-e", "--random-source=/dev/zero", "-n", "--help"]:
            res = self._run_phrasegen([flag])
            self.assertEqual(res.returncode, 1, f"Failed to reject flag: {flag}")
            self.assertIn("Usage: phrasegen [words (1-1000)]", res.stderr)

    def test_invalid_delimiter_with_newline_rejected(self):
        res = self._run_phrasegen(["3", "\n"])
        self.assertEqual(res.returncode, 1)
        self.assertIn("phrasegen: delimiter cannot contain newline", res.stderr)

    def test_missing_wordlists_exits_with_error(self):
        empty_dir = tempfile.mkdtemp()
        try:
            res = self._run_phrasegen(env_extra={"XDG_CONFIG_HOME": empty_dir})
            self.assertEqual(res.returncode, 1)
            self.assertIn("phrasegen: no wordlist files found", res.stderr)
        finally:
            shutil.rmtree(empty_dir, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
