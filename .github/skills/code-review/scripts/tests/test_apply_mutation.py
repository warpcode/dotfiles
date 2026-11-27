"""Tests for review-pull-request/scripts/apply_mutation.py.

A mutation that silently does not apply proves nothing, so the "pattern not
found" and "found fewer times than required" cases are hard errors rather than
warnings.
"""

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "apply_mutation.py")
)

SRC = textwrap.dedent(
    """\
    package pkg

    func F(key string) string {
    \tif key == "" {
    \t\treturn "fallback"
    \t}
    \treturn key
    }
    """
)


def run(spec, root, *args):
    return subprocess.run(
        [sys.executable, SCRIPT, "-", "--root", root] + list(args),
        input=json.dumps(spec),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


class ApplyMutationTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = self._tmp.name
        self.path = os.path.join(self.root, "f.go")
        with open(self.path, "w") as fh:
            fh.write(SRC)

    def read(self):
        with open(self.path) as fh:
            return fh.read()

    def test_replaces_the_matched_text(self):
        res = run(
            {"path": "f.go", "old": 'if key == "" {', "new": "if false {"},
            self.root,
        )
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("if false {", self.read())
        self.assertEqual(self.read(), SRC.replace('if key == "" {', "if false {"))

    def test_empty_new_deletes_the_matched_text(self):
        block = '\tif key == "" {\n\t\treturn "fallback"\n\t}\n'
        res = run({"path": "f.go", "old": block, "new": ""}, self.root)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertNotIn("fallback", self.read())

    def test_missing_pattern_is_an_error_not_a_silent_no_op(self):
        res = run({"path": "f.go", "old": "no such text", "new": "x"}, self.root)
        self.assertEqual(res.returncode, 1)
        self.assertIn("pattern not found", res.stderr)
        self.assertEqual(self.read(), SRC)

    def test_count_larger_than_occurrences_is_rejected(self):
        with open(self.path, "w") as fh:
            fh.write("x\nx\n")
        res = run({"path": "f.go", "old": "x", "new": "y", "count": 3}, self.root)
        self.assertEqual(res.returncode, 1)
        self.assertIn("need 3", res.stderr)
        self.assertEqual(self.read(), "x\nx\n")

    def test_count_replaces_exactly_that_many(self):
        with open(self.path, "w") as fh:
            fh.write("a\na\na\n")
        res = run({"path": "f.go", "old": "a", "new": "b", "count": 2}, self.root)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.read(), "b\nb\na\n")

    def test_check_reports_presence_without_writing(self):
        res = run(
            {"path": "f.go", "old": 'if key == "" {', "new": "x"},
            self.root,
            "--check",
        )
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("FOUND", res.stdout)
        self.assertEqual(self.read(), SRC)

    def test_missing_key_is_a_usage_error(self):
        res = run({"path": "f.go"}, self.root)
        self.assertEqual(res.returncode, 2)
        self.assertIn("missing 'old'", res.stderr)

    def test_invalid_json_is_a_usage_error(self):
        res = subprocess.run(
            [sys.executable, SCRIPT, "-", "--root", self.root],
            input="{not json",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.assertEqual(res.returncode, 2)

    def test_unreadable_file_is_a_usage_error(self):
        res = run({"path": "nope.go", "old": "a", "new": "b"}, self.root)
        self.assertEqual(res.returncode, 2)

    def test_embedded_newlines_survive(self):
        old = 'if key == "" {\n\t\treturn "fallback"\n\t}'
        res = run({"path": "f.go", "old": old, "new": "return key"}, self.root)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("return key", self.read())

    def test_path_traversal_absolute_path_blocked(self):
        res = run({"path": "/etc/passwd", "old": "root", "new": "hacked"}, self.root)
        self.assertEqual(res.returncode, 2)
        self.assertIn("target path is outside root directory", res.stderr)

    def test_path_traversal_relative_parent_blocked(self):
        res = run({"path": "../../etc/passwd", "old": "root", "new": "hacked"}, self.root)
        self.assertEqual(res.returncode, 2)
        self.assertIn("target path is outside root directory", res.stderr)


if __name__ == "__main__":
    unittest.main()