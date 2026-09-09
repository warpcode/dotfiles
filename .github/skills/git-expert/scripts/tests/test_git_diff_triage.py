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

parse_args = git_diff_triage.parse_args
split_diff_into_chunks = git_diff_triage.split_diff_into_chunks
count_body_lines = git_diff_triage.count_body_lines
header_only = git_diff_triage.header_only


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

if __name__ == "__main__":
    unittest.main()
