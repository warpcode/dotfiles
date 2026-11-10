import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestFFmpegRip(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.script_path = str(self.repo_root / "dot_local" / "bin" / "executable_ffmpeg-rip")
        self.test_dir = tempfile.mkdtemp()

        # Create a mock ffmpeg binary so ffmpeg-rip can execute in environments without ffmpeg installed
        self.bin_dir = Path(self.test_dir) / "bin"
        self.bin_dir.mkdir()
        self.mock_ffmpeg = self.bin_dir / "ffmpeg"
        self.mock_ffmpeg.write_text(
            "#!/usr/bin/env bash\n"
            "if [[ \"$*\" == *\"-codecs\"* ]]; then\n"
            "    echo 'Codecs: libfdk_aac aac'\n"
            "    exit 0\n"
            "fi\n"
            "exit 0\n"
        )
        self.mock_ffmpeg.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.bin_dir}:{self.env.get('PATH', '')}"

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_argument_exits_with_error(self):
        res = subprocess.run(
            ["python3", self.script_path],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("usage:", res.stderr.lower())

    def test_nonexistent_source_exits_with_error(self):
        res = subprocess.run(
            ["python3", self.script_path, "nonexistent_video.mp4"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("does not exist or is not a file", res.stderr)

    def test_print_command_outputs_expected_command(self):
        sample_file = Path(self.test_dir) / "test.mkv"
        sample_file.write_text("mock video content")

        res = subprocess.run(
            ["python3", self.script_path, "-print-command", str(sample_file)],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        cmd_output = res.stdout.strip()

        self.assertIn("-i " + str(sample_file), cmd_output)
        expected_output = str(sample_file.with_name("test-encoded.mp4"))
        self.assertIn(expected_output, cmd_output)

    def test_dash_prefixed_filename_normalized_to_prevent_option_injection(self):
        dash_file = Path(self.test_dir) / "-dash-video.mp4"
        dash_file.write_text("mock video content")

        res = subprocess.run(
            ["python3", self.script_path, "-print-command", "--", "-dash-video.mp4"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        cmd_output = res.stdout.strip()

        # The input and output starting with '-' must be normalized with './'
        self.assertIn("-i ./-dash-video.mp4", cmd_output)
        self.assertIn("./-dash-video-encoded.mp4", cmd_output)
        # Verify that '--' is NOT passed to ffmpeg
        self.assertNotIn("-- ./-dash-video.mp4", cmd_output)


if __name__ == "__main__":
    unittest.main()
