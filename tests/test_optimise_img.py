import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestOptimiseImgScript(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parent.parent
        self.script_path = str(self.repo_root / "dot_local" / "bin" / "executable_optimise-img")
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_missing_input_file_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("No input file specified", res.stdout)

    def test_nonexistent_input_file_exits_with_error(self):
        res = subprocess.run(
            ["bash", self.script_path, "nonexistent.png"],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("No input file specified", res.stdout)

    def test_invalid_file_type_exits_with_error(self):
        test_txt = Path(self.test_dir) / "test.txt"
        test_txt.write_text("dummy content")
        res = subprocess.run(
            ["bash", self.script_path, str(test_txt)],
            cwd=self.test_dir,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("Invalid file type", res.stdout)

    def test_png_optimization_uses_mktemp_and_not_predictable_tmp(self):
        # Create mock tools (pngcrush, optipng) that record command invocations and verify mktemp paths
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()

        mock_pngcrush = mock_bin_dir / "pngcrush"
        mock_pngcrush.write_text(
            "#!/usr/bin/env bash\n"
            "out_file=\"${!#}\"\n"
            "echo \"$out_file\" > \"$TMP_LOG_DIR/pngcrush_out.txt\"\n"
            "echo 'crushed-png' > \"$out_file\"\n"
        )
        mock_pngcrush.chmod(0o755)

        mock_optipng = mock_bin_dir / "optipng"
        mock_optipng.write_text(
            "#!/usr/bin/env bash\n"
            "out_file=\"${!#}\"\n"
            "echo \"$out_file\" > \"$TMP_LOG_DIR/optipng_out.txt\"\n"
            "echo 'opt-png-slightly-longer-content' > \"$out_file\"\n"
        )
        mock_optipng.chmod(0o755)

        log_dir = Path(self.test_dir) / "logs"
        log_dir.mkdir()
        custom_tmp = Path(self.test_dir) / "tmp"
        custom_tmp.mkdir()

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"
        env["TMPDIR"] = str(custom_tmp)
        env["TMP_LOG_DIR"] = str(log_dir)

        test_png = Path(self.test_dir) / "input.png"
        test_png.write_text("original-png-content-that-is-longer-than-crushed")

        dest_png = Path(self.test_dir) / "output.png"

        res = subprocess.run(
            ["bash", self.script_path, str(test_png), str(dest_png)],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")

        pngcrush_out = (log_dir / "pngcrush_out.txt").read_text().strip()
        optipng_out = (log_dir / "optipng_out.txt").read_text().strip()

        # Check that files were created within custom_tmp (using TMPDIR) and match mktemp template
        self.assertTrue(pngcrush_out.startswith(str(custom_tmp)))
        self.assertIn("optimise-img-png1-", pngcrush_out)
        self.assertTrue(optipng_out.startswith(str(custom_tmp)))
        self.assertIn("optimise-img-png2-", optipng_out)

        # Ensure destination file has the smaller crushed content
        self.assertEqual(dest_png.read_text().strip(), "crushed-png")

    def test_jpeg_optimization_uses_mktemp(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()

        mock_jpegoptim = mock_bin_dir / "jpegoptim"
        mock_jpegoptim.write_text(
            "#!/usr/bin/env bash\n"
            "target=\"${!#}\"\n"
            "echo \"$target\" > \"$TMP_LOG_DIR/jpegoptim_target.txt\"\n"
            "echo 'opt-jpg' > \"$target\"\n"
        )
        mock_jpegoptim.chmod(0o755)

        log_dir = Path(self.test_dir) / "logs"
        log_dir.mkdir()
        custom_tmp = Path(self.test_dir) / "tmp"
        custom_tmp.mkdir()

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"
        env["TMPDIR"] = str(custom_tmp)
        env["TMP_LOG_DIR"] = str(log_dir)

        test_jpg = Path(self.test_dir) / "input.jpg"
        test_jpg.write_text("original-jpeg-longer-content")

        dest_jpg = Path(self.test_dir) / "output.jpg"

        res = subprocess.run(
            ["bash", self.script_path, str(test_jpg), str(dest_jpg)],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")

        jpegoptim_target = (log_dir / "jpegoptim_target.txt").read_text().strip()
        self.assertTrue(jpegoptim_target.startswith(str(custom_tmp)))
        self.assertIn("optimise-img-jpg-", jpegoptim_target)
        self.assertEqual(dest_jpg.read_text().strip(), "opt-jpg")

    def test_gif_optimization_uses_mktemp(self):
        mock_bin_dir = Path(self.test_dir) / "bin"
        mock_bin_dir.mkdir()

        mock_gifsicle = mock_bin_dir / "gifsicle"
        mock_gifsicle.write_text(
            "#!/usr/bin/env bash\n"
            "out_file=\"${!#}\"\n"
            "echo \"$out_file\" > \"$TMP_LOG_DIR/gifsicle_out.txt\"\n"
            "echo 'opt-gif' > \"$out_file\"\n"
        )
        mock_gifsicle.chmod(0o755)

        log_dir = Path(self.test_dir) / "logs"
        log_dir.mkdir()
        custom_tmp = Path(self.test_dir) / "tmp"
        custom_tmp.mkdir()

        env = os.environ.copy()
        env["PATH"] = f"{mock_bin_dir}:{env.get('PATH', '')}"
        env["TMPDIR"] = str(custom_tmp)
        env["TMP_LOG_DIR"] = str(log_dir)

        test_gif = Path(self.test_dir) / "input.gif"
        test_gif.write_text("original-gif-longer-content")

        dest_gif = Path(self.test_dir) / "output.gif"

        res = subprocess.run(
            ["bash", self.script_path, str(test_gif), str(dest_gif)],
            cwd=self.test_dir,
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout: {res.stdout}, stderr: {res.stderr}")

        gifsicle_out = (log_dir / "gifsicle_out.txt").read_text().strip()
        self.assertTrue(gifsicle_out.startswith(str(custom_tmp)))
        self.assertIn("optimise-img-gif-", gifsicle_out)
        self.assertEqual(dest_gif.read_text().strip(), "opt-gif")


if __name__ == "__main__":
    unittest.main()
