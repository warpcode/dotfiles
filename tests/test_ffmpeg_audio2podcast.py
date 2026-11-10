import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestFFmpegAudio2Podcast(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.script_path = str(self.repo_root / "dot_local" / "bin" / "executable_ffmpeg-audio2podcast")
        self.test_dir = tempfile.mkdtemp()

        # Create a mock ffmpeg binary so ffmpeg-audio2podcast can execute in environments without ffmpeg installed
        self.bin_dir = Path(self.test_dir) / "bin"
        self.bin_dir.mkdir()
        self.mock_ffmpeg = self.bin_dir / "ffmpeg"
        self.mock_ffmpeg.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' \"$@\" >> \"${TEST_INVOCATIONS_LOG:-/dev/null}\"\n"
            "if [[ \"$*\" == *\"-formats\"* ]]; then\n"
            "    echo 'File formats:  E mp4             MP4 (MPEG-4 Part 14)'\n"
            "    exit 0\n"
            "fi\n"
            "if [[ \"$*\" == *\"-codecs\"* ]]; then\n"
            "    echo 'Codecs: libfdk_aac aac'\n"
            "    exit 0\n"
            "fi\n"
            "exit 0\n"
        )
        self.mock_ffmpeg.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.bin_dir}:{self.env.get('PATH', '')}"
        self.log_file = Path(self.test_dir) / "ffmpeg_invocations.txt"
        self.env["TEST_INVOCATIONS_LOG"] = str(self.log_file)

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_source_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("No Source specified", res.stdout)

    def test_nonexistent_source_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path, "nonexistent_source.mp4"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("does not exist or is not a file", res.stderr)

    def test_missing_output_exits_with_error(self):
        sample_file = Path(self.test_dir) / "sample.avi"
        sample_file.write_text("dummy media content")

        res = subprocess.run(
            ["bash", self.script_path, str(sample_file)],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("No Output specified", res.stdout)

    def test_invalid_output_extension_exits_with_error(self):
        sample_file = Path(self.test_dir) / "sample.avi"
        sample_file.write_text("dummy media content")

        res = subprocess.run(
            ["bash", self.script_path, str(sample_file), "output.wav"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Output file must end with mp4 or m4a", res.stdout)

    def test_successful_conversion_invokes_ffmpeg(self):
        sample_file = Path(self.test_dir) / "sample.avi"
        sample_file.write_text("dummy media content")

        res = subprocess.run(
            ["bash", self.script_path, str(sample_file), "podcast.m4a"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        self.assertTrue(self.log_file.exists())
        log_content = self.log_file.read_text()
        self.assertIn(str(sample_file), log_content)
        self.assertIn("podcast.m4a", log_content)

    def test_dash_prefixed_files_normalized_to_prevent_option_injection(self):
        dash_file = Path(self.test_dir) / "-dash-source.mp4"
        dash_file.write_text("dummy media content")

        res = subprocess.run(
            ["bash", self.script_path, "-dash-source.mp4", "-dash-output.m4a"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        self.assertTrue(self.log_file.exists())
        invocations = self.log_file.read_text().splitlines()

        # Both the input and output arguments must be prefixed with ./ to avoid being treated as options
        self.assertIn("./-dash-source.mp4", invocations)
        self.assertIn("./-dash-output.m4a", invocations)
        self.assertNotIn("-dash-source.mp4", [arg for arg in invocations if arg == "-dash-source.mp4"])
        self.assertNotIn("-dash-output.m4a", [arg for arg in invocations if arg == "-dash-output.m4a"])


if __name__ == "__main__":
    unittest.main()
