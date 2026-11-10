import json
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
            "if [[ -n \"${MOCK_INVALID_DATA:-}\" && \"$1\" == \"-i\" ]]; then\n"
            "    echo 'Invalid data found when processing input' >&2\n"
            "    exit 1\n"
            "fi\n"
            "python3 -c 'import sys, json; open(sys.argv[1], \"a\").write(json.dumps(sys.argv[2:]) + \"\\n\")' "
            "\"${TEST_INVOCATIONS_LOG:-/dev/null}\" \"$@\"\n"
            "if [[ \"$1\" == \"-formats\" ]]; then\n"
            "    echo 'File formats:  E mp4             MP4 (MPEG-4 Part 14)'\n"
            "    exit 0\n"
            "fi\n"
            "if [[ \"$1\" == \"-codecs\" ]]; then\n"
            "    echo 'Codecs: libfdk_aac aac'\n"
            "    exit 0\n"
            "fi\n"
            "exit 0\n"
        )
        self.mock_ffmpeg.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.bin_dir}:{self.env.get('PATH', '')}"
        self.log_file = Path(self.test_dir) / "ffmpeg_invocations.jsonl"
        self.env["TEST_INVOCATIONS_LOG"] = str(self.log_file)

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def get_invocations(self):
        if not self.log_file.exists():
            return []
        lines = [line.strip() for line in self.log_file.read_text().splitlines() if line.strip()]
        return [json.loads(line) for line in lines]

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

    def test_invalid_data_found_exits_with_code_one(self):
        sample_file = Path(self.test_dir) / "corrupted.mp4"
        sample_file.write_text("corrupted content")

        env = self.env.copy()
        env["MOCK_INVALID_DATA"] = "1"
        res = subprocess.run(
            ["bash", self.script_path, str(sample_file)],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn(f"{sample_file} is NOT A VALID FILE!", res.stdout)

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
        invocations = self.get_invocations()
        self.assertGreaterEqual(len(invocations), 4)

        # Invocations sequence:
        # 1. Validation probe: ffmpeg -i <source>
        self.assertEqual(invocations[0], ["-i", str(sample_file)])
        # 2. Format check: ffmpeg -formats
        self.assertEqual(invocations[1], ["-formats"])
        # 3. Codec check: ffmpeg -codecs
        self.assertEqual(invocations[2], ["-codecs"])
        # 4. Conversion invocation
        conversion_cmd = invocations[3]
        expected_prefix = ["-y", "-v", "error", "-stats", "-i", str(sample_file), "-vn", "-sn", "-c:a", "libfdk_aac", "-b:a", "32k", "-ac", "2", "podcast.m4a"]
        self.assertEqual(conversion_cmd, expected_prefix)

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
        invocations = self.get_invocations()
        self.assertGreaterEqual(len(invocations), 4)

        # Check conversion invocation arguments
        conversion_cmd = invocations[3]
        self.assertIn("./-dash-source.mp4", conversion_cmd)
        self.assertIn("./-dash-output.m4a", conversion_cmd)
        self.assertNotIn("-dash-source.mp4", conversion_cmd)
        self.assertNotIn("-dash-output.m4a", conversion_cmd)


if __name__ == "__main__":
    unittest.main()
