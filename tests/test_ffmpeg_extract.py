import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestFFmpegExtract(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.script_path = str(self.repo_root / "dot_local" / "bin" / "executable_ffmpeg-extract")
        self.test_dir = tempfile.mkdtemp()

        # Create mock ffmpeg and ffprobe binaries so ffmpeg-extract can execute in environments without ffmpeg installed
        self.bin_dir = Path(self.test_dir) / "bin"
        self.bin_dir.mkdir()
        self.mock_ffmpeg = self.bin_dir / "ffmpeg"
        self.mock_ffmpeg.write_text(
            "#!/usr/bin/env bash\n"
            "if [[ -n \"${MOCK_INVALID_DATA:-}\" && \"$1\" == \"-i\" ]]; then\n"
            "    echo 'Invalid data found when processing input' >&2\n"
            "    exit 1\n"
            "fi\n"
            "python3 -c 'import sys, json; open(sys.argv[1], \"a\").write(json.dumps([\"ffmpeg\"] + sys.argv[2:]) + \"\\n\")' "
            "\"${TEST_INVOCATIONS_LOG:-/dev/null}\" \"$@\"\n"
            "exit 0\n"
        )
        self.mock_ffmpeg.chmod(0o755)

        self.mock_ffprobe = self.bin_dir / "ffprobe"
        self.mock_ffprobe.write_text(
            "#!/usr/bin/env bash\n"
            "python3 -c 'import sys, json; open(sys.argv[1], \"a\").write(json.dumps([\"ffprobe\"] + sys.argv[2:]) + \"\\n\")' "
            "\"${TEST_INVOCATIONS_LOG:-/dev/null}\" \"$@\"\n"
            "echo '    Stream #0:0: Video: h264'\n"
            "echo '    Stream #0:1: Audio: aac'\n"
            "exit 0\n"
        )
        self.mock_ffprobe.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.bin_dir}:{self.env.get('PATH', '')}"
        self.log_file = Path(self.test_dir) / "tool_invocations.jsonl"
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

    def test_successful_extraction_invokes_ffmpeg_and_ffprobe(self):
        sample_file = Path(self.test_dir) / "sample.mp4"
        sample_file.write_text("dummy media content")

        res = subprocess.run(
            ["bash", self.script_path, str(sample_file)],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        invocations = self.get_invocations()
        self.assertGreaterEqual(len(invocations), 3)

        # 1. Validation probe: ffmpeg -i <source>
        self.assertEqual(invocations[0], ["ffmpeg", "-i", str(sample_file)])
        # 2. Probe streams: ffprobe <source>
        self.assertEqual(invocations[1], ["ffprobe", str(sample_file)])
        # 3. Extraction invocation: ffmpeg -v error -stats -i <source> ...
        extraction_cmd = invocations[2]
        self.assertEqual(extraction_cmd[:5], ["ffmpeg", "-v", "error", "-stats", "-i"])
        self.assertEqual(extraction_cmd[5], str(sample_file))

    def test_dash_prefixed_files_normalized_to_prevent_option_injection(self):
        dash_file = Path(self.test_dir) / "-dash-source.mp4"
        dash_file.write_text("dummy media content")

        res = subprocess.run(
            ["bash", self.script_path, "-dash-source.mp4"],
            cwd=self.test_dir,
            env=self.env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")
        invocations = self.get_invocations()
        self.assertGreaterEqual(len(invocations), 3)

        # Probe check: ffmpeg -i ./-dash-source.mp4
        self.assertEqual(invocations[0], ["ffmpeg", "-i", "./-dash-source.mp4"])
        # Probe streams: ffprobe ./-dash-source.mp4
        self.assertEqual(invocations[1], ["ffprobe", "./-dash-source.mp4"])

        # Check extraction invocation arguments
        extraction_cmd = invocations[2]
        self.assertIn("./-dash-source.mp4", extraction_cmd)
        self.assertNotIn("-dash-source.mp4", extraction_cmd)


if __name__ == "__main__":
    unittest.main()
