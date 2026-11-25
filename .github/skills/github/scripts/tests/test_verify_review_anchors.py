"""Tests for review-pull-request/scripts/verify_review_anchors.sh.

The anchor-parsing awk has produced two silent wrong answers in production
(2026-09-24 off-by-one, 2026-09-26 a transcribed one-liner reading the
pre-change hunk start), and the `--head` cross-check used to abort with exit
128 and no verdict when a path was missing from the ref. These tests pin both
classes of failure.

Fixtures are real git repos with real diffs; nothing here mocks the awk.
"""

import os
import subprocess
import tempfile
import textwrap
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "verify_review_anchors.sh")
)


def run(args, cwd=None):
    # cwd must be the fixture directory: every --head/--diff lookup is
    # resolved relative to the repository being inspected.
    return subprocess.run(
        ["bash", SCRIPT] + args,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


class AnchorVerifierTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = self._tmp.name

    def write(self, name, content):
        path = os.path.join(self.dir, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as fh:
            fh.write(textwrap.dedent(content).lstrip("\n"))
        return path

    def payload(self, *pairs):
        import json
        path = os.path.join(self.dir, "payload.json")
        with open(path, "w") as fh:
            json.dump(
                {
                    "comments": [
                        {"path": p, "line": n, "side": "RIGHT", "body": "x"}
                        for p, n in pairs
                    ]
                },
                fh,
            )
        return path

    def git(self, *args):
        return subprocess.run(
            ["git"] + list(args),
            cwd=self.dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )

    def init_repo(self, filename="f.go", body="l1\nl2\nl3\n"):
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "a@b")
        self.git("config", "user.name", "a")
        self.write(filename, body)
        self.git("add", "-A")
        self.git("commit", "-qm", "base")

    # --- hunk arithmetic -----------------------------------------------------

    def test_added_line_passes_and_context_line_fails(self):
        diff = self.write(
            "p.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,2 +1,3 @@
             l1
            +added
             l3
            """,
        )
        ok = run(["--diff", diff, "--path", "f.go", "--line", "2"], cwd=self.dir)
        self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)
        self.assertIn("VERDICT: PASS", ok.stdout)

        # Line 1 is a context line, not an added line: must FAIL.
        bad = run(["--diff", diff, "--path", "f.go", "--line", "1"], cwd=self.dir)
        self.assertEqual(bad.returncode, 1)
        self.assertIn("VERDICT: FAIL", bad.stdout)

    def test_post_change_line_numbering_across_hunks(self):
        """The regression that made every anchor look invalid: reading hunk
        field $2 (pre-change) instead of $3 (post-change)."""
        diff = self.write(
            "two.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,1 +1,2 @@
             l1
            +added one
            @@ -10,2 +11,3 @@
             l10
            +added two
             l11
            """,
        )
        # Second hunk starts at post-change line 11; its first added line is 12.
        res = run(["--diff", diff, "--path", "f.go", "--line", "12"], cwd=self.dir)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)

    def test_plus_branch_tests_before_incrementing(self):
        """An added line must be matched at its own number, not the next one."""
        diff = self.write(
            "off.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -0,0 +1,2 @@
            +first
            +second
            """,
        )
        for line in (1, 2):
            res = run(["--diff", diff, "--path", "f.go", "--line", str(line)], cwd=self.dir)
            self.assertEqual(res.returncode, 0, f"line {line}: {res.stdout}")

    def test_removed_line_is_not_a_valid_anchor(self):
        diff = self.write(
            "del.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,3 +1,2 @@
             l1
            -l2
             l3
            """,
        )
        res = run(["--diff", diff, "--path", "f.go", "--line", "2"], cwd=self.dir)
        self.assertEqual(res.returncode, 1)
        self.assertIn("VERDICT: FAIL", res.stdout)

    # --- --head cross-check --------------------------------------------------

    def test_head_ref_prints_the_anchored_line_text(self):
        self.init_repo()
        diff = self.write(
            "h.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,2 +1,3 @@
             l1
            +l2
             l3
            """,
        )
        res = run(["--diff", diff, "--path", "f.go", "--line", "2", "--head", "HEAD"], cwd=self.dir)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("l2", res.stdout)

    def test_absent_path_in_head_ref_fails_with_a_verdict_not_exit_128(self):
        """Regression: `git show ref:missing` propagated under
        `set -euo pipefail`, killing the loop so the script exited 128 having
        printed no VERDICT at all. The caller could not tell a bad anchor from
        a broken ref lookup."""
        self.init_repo()
        diff = self.write(
            "a.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,2 +1,3 @@
             l1
            +l2
             l3
            diff --git a/gone.go b/gone.go
            deleted file mode 100644
            --- a/gone.go
            +++ /dev/null
            @@ -1,1 +0,0 @@
            -was here
            """,
        )
        pay = self.payload(("f.go", 2), ("gone.go", 1))
        res = run(["--diff", diff, "--payload", pay, "--head", "HEAD"], cwd=self.dir)
        self.assertNotEqual(
            res.returncode, 128,
            f"must not abort with 128: {res.stdout}{res.stderr}",
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("VERDICT: FAIL", res.stdout + res.stderr)

    def test_wrong_ref_is_reported_as_a_failed_cross_check(self):
        self.init_repo()
        diff = self.write(
            "w.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,2 +1,3 @@
             l1
            +l2
             l3
            """,
        )
        res = run(["--diff", diff, "--path", "f.go", "--line", "2",
                   "--head", "no-such-ref-xyz"], cwd=self.dir)
        self.assertNotEqual(res.returncode, 128)
        self.assertEqual(res.returncode, 1)

    def test_blank_added_line_is_a_valid_anchor(self):
        """An added line may be empty. 'No text from the ref' must not be
        mistaken for a failed lookup."""
        self.init_repo(body="package x\n\nfunc F() {\n}\n")
        diff = self.write(
            "b.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -0,0 +1,4 @@
            +package x
            +
            +func F() {
            +}
            """,
        )
        pay = self.payload(("f.go", 2), ("f.go", 4))
        res = run(["--diff", diff, "--payload", pay, "--head", "HEAD"], cwd=self.dir)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("VERDICT: PASS", res.stdout)

    def test_line_beyond_eof_is_rejected(self):
        self.init_repo()
        diff = self.write(
            "e.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,1 +1,3 @@
             l1
            +l2
            +l3
            """,
        )
        res = run(["--diff", diff, "--path", "f.go", "--line", "99", "--head", "HEAD"], cwd=self.dir)
        self.assertEqual(res.returncode, 1)
        self.assertIn("beyond EOF", res.stdout)

    # --- argument handling ---------------------------------------------------

    def test_missing_diff_is_a_usage_error(self):
        res = run(["--path", "f.go", "--line", "1"], cwd=self.dir)
        self.assertEqual(res.returncode, 2)
        self.assertIn("--diff is required", res.stderr)

    def test_no_anchors_is_a_usage_error(self):
        diff = self.write("x.diff", "diff --git a/f b/f\n")
        res = run(["--diff", diff], cwd=self.dir)
        self.assertEqual(res.returncode, 2)
        self.assertIn("no anchors supplied", res.stderr)

    def test_line_without_preceding_path_is_rejected(self):
        diff = self.write("x.diff", "diff --git a/f b/f\n")
        res = run(["--diff", diff, "--line", "3"], cwd=self.dir)
        self.assertEqual(res.returncode, 2)

    def test_quiet_prints_only_the_verdict(self):
        diff = self.write(
            "q.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,2 +1,3 @@
             l1
            +l2
             l3
            """,
        )
        res = run(["--diff", diff, "--path", "f.go", "--line", "2", "--quiet"], cwd=self.dir)
    def test_list_anchors_prints_added_lines(self):
        diff = self.write(
            "l.diff",
            """
            diff --git a/f.go b/f.go
            --- a/f.go
            +++ b/f.go
            @@ -1,2 +1,4 @@
             l1
            +added_line_2
            +added_line_3
             l4
            """,
        )
        res = run(["--diff", diff, "--list"], cwd=self.dir)
        self.assertEqual(res.returncode, 0)
        lines = res.stdout.strip().splitlines()
        self.assertEqual(len(lines), 2)
        self.assertEqual(lines[0], "f.go:2: added_line_2")
        self.assertEqual(lines[1], "f.go:3: added_line_3")


if __name__ == "__main__":
    unittest.main()