import importlib.util
import os
import sys
import unittest

# Dynamically import the git-diff-triage script
script_path = os.path.join(os.path.dirname(__file__), "..", "git-diff-triage.py")
spec = importlib.util.spec_from_file_location("git_diff_triage", script_path)
git_diff_triage = importlib.util.module_from_spec(spec)
sys.modules["git_diff_triage"] = git_diff_triage
spec.loader.exec_module(git_diff_triage)

from io import StringIO
import subprocess
from unittest.mock import MagicMock, patch

parse_args = git_diff_triage.parse_args
split_diff_into_chunks = git_diff_triage.split_diff_into_chunks
count_body_lines = git_diff_triage.count_body_lines
header_only = git_diff_triage.header_only
run_git_diff = git_diff_triage.run_git_diff
DEFAULT_DIFF_FLAGS = git_diff_triage.DEFAULT_DIFF_FLAGS


class TestGitDiffTriage(unittest.TestCase):
    def test_parse_args_defaults(self):
        args = parse_args([])
        self.assertEqual(args.threshold, 40)
        self.assertFalse(args.raw)
        self.assertEqual(args.diff_args, [])

    def test_parse_args_custom_threshold(self):
        args = parse_args(["--threshold", "100"])
        self.assertEqual(args.threshold, 100)

    def test_parse_args_raw(self):
        args = parse_args(["--raw"])
        self.assertTrue(args.raw)

        args_alias = parse_args(["--raw-output"])
        self.assertTrue(args_alias.raw)

    def test_parse_args_diff_args(self):
        args = parse_args(["--", "HEAD~1", "HEAD"])
        self.assertEqual(args.diff_args, ["HEAD~1", "HEAD"])

        args = parse_args(["--threshold", "50", "--", "master"])
        self.assertEqual(args.diff_args, ["master"])

    def test_parse_args_without_dashes_separator(self):
        args = parse_args(["HEAD~1", "HEAD"])
        self.assertEqual(args.diff_args, ["HEAD~1", "HEAD"])

    def test_parse_args_invalid_threshold(self):
        with self.assertRaises(SystemExit):
            with unittest.mock.patch("sys.stderr"):
                parse_args(["--threshold", "invalid"])

    def test_parse_args_complex_combination(self):
        args = parse_args(["--threshold", "15", "--raw", "--", "file1.py", "file2.py"])
        self.assertEqual(args.threshold, 15)
        self.assertTrue(args.raw)
        self.assertEqual(args.diff_args, ["file1.py", "file2.py"])

    def test_parse_args_help(self):
        with self.assertRaises(SystemExit) as cm:
            with unittest.mock.patch("sys.stdout"):
                parse_args(["--help"])
        self.assertEqual(cm.exception.code, 0)

    def test_split_diff_into_chunks_empty(self):
        self.assertEqual(split_diff_into_chunks(""), [])

    def test_split_diff_into_chunks_single(self):
        diff = "diff --git a/file b/file\nindex 123..456 100644\n--- a/file\n+++ b/file\n@@ -1 +1 @@\n-a\n+b\n"
        chunks = split_diff_into_chunks(diff)
        self.assertEqual(len(chunks), 1)
        self.assertEqual(chunks[0], diff)

    def test_split_diff_into_chunks_multiple(self):
        diff = (
            "diff --git a/file1 b/file1\n"
            "index 123..456 100644\n"
            "--- a/file1\n"
            "+++ b/file1\n"
            "diff --git a/file2 b/file2\n"
            "index 789..abc 100644\n"
        )
        chunks = split_diff_into_chunks(diff)
        self.assertEqual(len(chunks), 2)
        self.assertEqual(chunks[0], "diff --git a/file1 b/file1\nindex 123..456 100644\n--- a/file1\n+++ b/file1\n")
        self.assertEqual(chunks[1], "diff --git a/file2 b/file2\nindex 789..abc 100644\n")

    def test_split_diff_into_chunks_with_preamble(self):
        diff = (
            "Some header or notice before first diff\n"
            "diff --git a/file1 b/file1\n"
            "index 123..456 100644\n"
            "--- a/file1\n"
            "+++ b/file1\n"
        )
        chunks = split_diff_into_chunks(diff)
        self.assertEqual(len(chunks), 2)
        self.assertEqual(chunks[0], "Some header or notice before first diff\n")
        self.assertEqual(chunks[1], "diff --git a/file1 b/file1\nindex 123..456 100644\n--- a/file1\n+++ b/file1\n")

    def test_split_diff_into_chunks_realistic_multifile(self):
        diff = (
            "diff --git a/src/main.py b/src/main.py\n"
            "index 0000000..1111111 100644\n"
            "--- a/src/main.py\n"
            "+++ b/src/main.py\n"
            "@@ -1,2 +1,3 @@\n"
            " import os\n"
            "+import sys\n"
            " print('hello')\n"
            "diff --git a/README.md b/README.md\n"
            "index 2222222..3333333 100644\n"
            "--- a/README.md\n"
            "+++ b/README.md\n"
            "@@ -5,3 +5,3 @@\n"
            "-Old docs\n"
            "+New docs\n"
            "diff --git a/deleted.txt b/deleted.txt\n"
            "deleted file mode 100644\n"
            "index 4444444..0000000\n"
            "--- a/deleted.txt\n"
            "+++ /dev/null\n"
            "@@ -1 +0,0 @@\n"
            "-bye\n"
        )
        chunks = split_diff_into_chunks(diff)
        self.assertEqual(len(chunks), 3)
        self.assertTrue(chunks[0].startswith("diff --git a/src/main.py"))
        self.assertIn("+import sys\n", chunks[0])
        self.assertTrue(chunks[1].startswith("diff --git a/README.md"))
        self.assertIn("+New docs\n", chunks[1])
        self.assertTrue(chunks[2].startswith("diff --git a/deleted.txt"))
        self.assertIn("-bye\n", chunks[2])
        self.assertEqual("".join(chunks), diff)

    def test_split_diff_into_chunks_diff_git_substring_in_hunk(self):
        # A line in the diff hunk might contain "diff --git " not at line start or modified line
        diff = (
            "diff --git a/script.py b/script.py\n"
            "index 111..222 100644\n"
            "--- a/script.py\n"
            "+++ b/script.py\n"
            "@@ -10,3 +10,3 @@\n"
            " # Run diff --git command here\n"
            "-cmd = 'diff --git a b'\n"
            "+cmd = 'git diff a b'\n"
            "diff --git a/other.py b/other.py\n"
            "index 333..444 100644\n"
        )
        chunks = split_diff_into_chunks(diff)
        self.assertEqual(len(chunks), 2)
        self.assertIn("-cmd = 'diff --git a b'\n", chunks[0])
        self.assertEqual(chunks[1], "diff --git a/other.py b/other.py\nindex 333..444 100644\n")

    def test_count_body_lines(self):
        chunk = (
            "diff --git a/f b/f\n"
            "--- a/f\n"
            "+++ b/f\n"
            "@@ -1,3 +1,3 @@\n"
            " context\n"
            "-removed 1\n"
            "-removed 2\n"
            "+added 1\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 1)
        self.assertEqual(removed, 2)

    def test_count_body_lines_ignores_headers(self):
        chunk = (
            "--- a/f\n"
            "+++ b/f\n"
            "-a\n"
            "+b\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 1)
        self.assertEqual(removed, 1)

    def test_count_body_lines_empty(self):
        added, removed = count_body_lines("")
        self.assertEqual(added, 0)
        self.assertEqual(removed, 0)

    def test_count_body_lines_header_only(self):
        chunk = (
            "diff --git a/file b/file\n"
            "old mode 100644\n"
            "new mode 100755\n"
            "index 1234567..89abcdef 100644\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 0)
        self.assertEqual(removed, 0)

    def test_count_body_lines_pure_additions(self):
        chunk = (
            "diff --git a/newfile b/newfile\n"
            "--- /dev/null\n"
            "+++ b/newfile\n"
            "@@ -0,0 +1,3 @@\n"
            "+line 1\n"
            "+line 2\n"
            "+line 3\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 3)
        self.assertEqual(removed, 0)

    def test_count_body_lines_pure_deletions(self):
        chunk = (
            "diff --git a/oldfile b/oldfile\n"
            "--- a/oldfile\n"
            "+++ /dev/null\n"
            "@@ -1,2 +0,0 @@\n"
            "-deleted line 1\n"
            "-deleted line 2\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 0)
        self.assertEqual(removed, 2)

    def test_count_body_lines_context_only(self):
        chunk = (
            "@@ -1,3 +1,3 @@\n"
            " line 1\n"
            " line 2\n"
            " line 3\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 0)
        self.assertEqual(removed, 0)

    def test_count_body_lines_multiple_hunks(self):
        chunk = (
            "diff --git a/f b/f\n"
            "--- a/f\n"
            "+++ b/f\n"
            "@@ -1,3 +1,4 @@\n"
            " unchanged\n"
            "-old line\n"
            "+new line 1\n"
            "+new line 2\n"
            "@@ -20,3 +21,2 @@\n"
            "-removed line\n"
            " unchanged\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 2)
        self.assertEqual(removed, 2)

    def test_count_body_lines_single_char_plus_minus(self):
        chunk = (
            "diff --git a/f b/f\n"
            "--- a/f\n"
            "+++ b/f\n"
            "@@ -1,2 +1,2 @@\n"
            "+\n"
            "-\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 1)
        self.assertEqual(removed, 1)

    def test_count_body_lines_crlf_line_endings(self):
        chunk = (
            "diff --git a/f b/f\r\n"
            "--- a/f\r\n"
            "+++ b/f\r\n"
            "@@ -1,2 +1,2 @@\r\n"
            "+added line\r\n"
            "-removed line\r\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 1)
        self.assertEqual(removed, 1)

    def test_count_body_lines_dev_null_headers(self):
        chunk = (
            "diff --git a/dev/null b/b.txt\n"
            "--- /dev/null\n"
            "+++ b/b.txt\n"
            "@@ -0,0 +1,2 @@\n"
            "+first\n"
            "+second\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 2)
        self.assertEqual(removed, 0)

    def test_count_body_lines_no_trailing_newline(self):
        chunk = (
            "--- a/f\n"
            "+++ b/f\n"
            "+added without newline"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 1)
        self.assertEqual(removed, 0)

    def test_count_body_lines_prefix_variations(self):
        chunk = (
            "--- a/f\n"
            "+++ b/f\n"
            "@@ -1,3 +1,3 @@\n"
            "++added with plus\n"
            "--removed with minus\n"
            "+ added with space\n"
            "- removed with space\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 2)
        self.assertEqual(removed, 2)

    def test_count_body_lines_hunk_header_lines(self):
        chunk = (
            "diff --git a/f b/f\n"
            "--- a/f\n"
            "+++ b/f\n"
            "@@ -1,5 +1,5 @@ @@\n"
            " context line\n"
        )
        added, removed = count_body_lines(chunk)
        self.assertEqual(added, 0)
        self.assertEqual(removed, 0)

    @patch("sys.stdout", new_callable=StringIO)
    @patch("sys.argv", ["git-diff-triage.py", "--threshold", "2"])
    @patch("git_diff_triage.run_git_diff")
    def test_main_function_threshold_truncation(self, mock_run_diff, mock_stdout):
        mock_run_diff.return_value = (
            "diff --git a/file b/file\n"
            "index 123..456 100644\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1,5 +1,5 @@\n"
            "+line 1\n"
            "+line 2\n"
            "+line 3\n"
        )
        git_diff_triage.main()
        output = mock_stdout.getvalue()
        self.assertIn("# [diff-triage] body omitted: +3/-0 lines (threshold 2)\n", output)
        self.assertNotIn("+line 1", output)

    @patch("sys.stdout", new_callable=StringIO)
    @patch("sys.argv", ["git-diff-triage.py", "--raw"])
    @patch("git_diff_triage.run_git_diff")
    def test_main_function_raw_output(self, mock_run_diff, mock_stdout):
        raw_diff = (
            "diff --git a/file b/file\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1 +1 @@\n"
            "+line 1\n"
        )
        mock_run_diff.return_value = raw_diff
        git_diff_triage.main()
        self.assertEqual(mock_stdout.getvalue(), raw_diff)

    @patch("sys.stdout", new_callable=StringIO)
    @patch("sys.argv", ["git-diff-triage.py"])
    @patch("git_diff_triage.run_git_diff")
    def test_main_function_binary_file(self, mock_run_diff, mock_stdout):
        binary_diff = (
            "diff --git a/image.png b/image.png\n"
            "Binary files a/image.png and b/image.png differ\n"
        )
        mock_run_diff.return_value = binary_diff
        git_diff_triage.main()
        output = mock_stdout.getvalue()
        self.assertIn("Binary files a/image.png and b/image.png differ", output)

    def test_header_only(self):
        chunk = (
            "diff --git a/file b/file\n"
            "index 1234567..89abcdef 100644\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1,3 +1,3 @@\n"
            " context\n"
            "-removed\n"
            "+added\n"
        )
        expected = (
            "diff --git a/file b/file\n"
            "index 1234567..89abcdef 100644\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1,3 +1,3 @@\n"
        )
        self.assertEqual(header_only(chunk), expected)

    def test_header_only_binary(self):
        chunk = (
            "diff --git a/bin b/bin\n"
            "index 123..456 100644\n"
            "Binary files a/bin and b/bin differ\n"
        )
        expected = chunk
        self.assertEqual(header_only(chunk), expected)

    def test_header_only_mode_changes(self):
        chunk = (
            "diff --git a/file b/file\n"
            "old mode 100644\n"
            "new mode 100755\n"
        )
        self.assertEqual(header_only(chunk), chunk)

    def test_header_only_all_prefixes(self):
        chunk = (
            "diff --git a/file b/file\n"
            "index 123..456 100644\n"
            "deleted file mode 100644\n"
            "new file mode 100644\n"
            "old mode 100644\n"
            "new mode 100755\n"
            "rename from file1\n"
            "rename to file2\n"
            "copy from file1\n"
            "copy to file2\n"
            "similarity index 100%\n"
            "dissimilarity index 50%\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1 +1 @@\n"
            "Binary files a/bin and b/bin differ\n"
        )
        self.assertEqual(header_only(chunk), chunk)

    def test_header_only_body_stripping(self):
        chunk = (
            "diff --git a/file b/file\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1,3 +1,3 @@\n"
            " unchanged context line\n"
            "-removed line\n"
            "+added line\n"
            "another context line\n"
        )
        expected = (
            "diff --git a/file b/file\n"
            "--- a/file\n"
            "+++ b/file\n"
            "@@ -1,3 +1,3 @@\n"
        )
        self.assertEqual(header_only(chunk), expected)

    def test_header_only_edge_cases(self):
        # Empty input string
        self.assertEqual(header_only(""), "")

        # Chunk without header lines
        no_headers = " unchanged line\n-deleted line\n+inserted line\n"
        self.assertEqual(header_only(no_headers), "")

        # Chunk with only header lines
        only_headers = (
            "diff --git a/file b/file\n"
            "index 123..456 100644\n"
            "--- a/file\n"
            "+++ b/file\n"
        )
        self.assertEqual(header_only(only_headers), only_headers)
    @patch("subprocess.run")
    def test_run_git_diff_success(self, mock_run):
        mock_result = MagicMock()
        mock_result.stdout = "diff --git a/a b/a\n"
        mock_run.return_value = mock_result

        extra_args = ["--staged", "HEAD"]
        output = run_git_diff(extra_args)

        mock_run.assert_called_once_with(
            ["git", "diff"] + DEFAULT_DIFF_FLAGS + extra_args,
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(output, "diff --git a/a b/a\n")

    @patch("sys.stderr", new_callable=StringIO)
    @patch("subprocess.run")
    def test_run_git_diff_called_process_error_with_stderr(self, mock_run, mock_stderr):
        error = subprocess.CalledProcessError(
            returncode=128,
            cmd=["git", "diff"],
            output="",
            stderr="fatal: not a git repository\n",
        )
        mock_run.side_effect = error

        with self.assertRaises(SystemExit) as cm:
            run_git_diff([])

        self.assertEqual(cm.exception.code, 1)
        self.assertIn("fatal: not a git repository", mock_stderr.getvalue())

    @patch("sys.stderr", new_callable=StringIO)
    @patch("subprocess.run")
    def test_run_git_diff_called_process_error_without_stderr(self, mock_run, mock_stderr):
        error = subprocess.CalledProcessError(
            returncode=2,
            cmd=["git", "diff"],
            output="",
            stderr="",
        )
        mock_run.side_effect = error

        with self.assertRaises(SystemExit) as cm:
            run_git_diff([])

        self.assertEqual(cm.exception.code, 1)
        self.assertIn("git diff failed with exit code 2", mock_stderr.getvalue())

if __name__ == "__main__":
    unittest.main()
