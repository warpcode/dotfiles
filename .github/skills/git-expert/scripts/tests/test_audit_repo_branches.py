#!/usr/bin/env python3
"""Unit tests for audit_repo_branches.py.

    python3 -m unittest discover -s tests
"""

import importlib.util
import pathlib
import sys
import unittest
from unittest import mock

SCRIPT = pathlib.Path(__file__).resolve().parent.parent / "audit_repo_branches.py"
spec = importlib.util.spec_from_file_location("audit_repo_branches", SCRIPT)
branches = importlib.util.module_from_spec(spec)
sys.modules["audit_repo_branches"] = branches
spec.loader.exec_module(branches)


class TestResolveRepo(unittest.TestCase):
    """owner/repo must come from the remote, never guessed from the directory."""

    def test_parses_ssh_remote(self):
        with mock.patch.object(branches, "run",
                               return_value=(0, "git@github.com:warpcode/dotfiles.git\n", "")):
            self.assertEqual(branches.resolve_repo(None), "warpcode/dotfiles")

    def test_parses_https_remote(self):
        with mock.patch.object(branches, "run",
                               return_value=(0, "https://github.com/warpcode/dotfiles\n", "")):
            self.assertEqual(branches.resolve_repo(None), "warpcode/dotfiles")

    def test_explicit_repo_wins(self):
        self.assertEqual(branches.resolve_repo("a/b"), "a/b")

    def test_unparseable_remote_exits(self):
        with mock.patch.object(branches, "run", return_value=(0, "not-a-url\n", "")):
            with self.assertRaises(SystemExit):
                branches.resolve_repo(None)


class TestBlobComparison(unittest.TestCase):
    def test_blob_returns_oid(self):
        with mock.patch.object(branches, "run", return_value=(0, "abc123\n", "")):
            self.assertEqual(branches.blob("origin/master", "a.py"), "abc123")

    def test_blob_none_when_path_absent(self):
        with mock.patch.object(branches, "run", return_value=(1, "", "")):
            self.assertIsNone(branches.blob("origin/master", "gone.py"))


class TestBranchVerdicts(unittest.TestCase):
    """Classification must never route unlanded work into the delete block."""

    def _row(self, **kw):
        base = {"branch": "b", "pr": 1, "pr_state": "CLOSED", "verdict": "REVIEW",
                "behind": 0, "ahead": 1, "files": 1, "landed": True,
                "unique_files": [], "reason": "test"}
        base.update(kw)
        return base

    def test_open_pr_is_keep(self):
        rows = [self._row(pr_state="OPEN", verdict="KEEP", landed=False,
                          unique_files=["x.py"])]
        out = branches.render(rows, [], "master", "o/r")
        self.assertIn("`KEEP`", out)
        self.assertNotIn("git push origin --delete", out)

    def test_merged_and_landed_is_deletable(self):
        rows = [self._row(pr_state="MERGED", verdict="DELETE_MERGED", landed=True)]
        out = branches.render(rows, [], "master", "o/r")
        self.assertIn("git push origin --delete", out)
        self.assertIn("`b`", out)

    def test_closed_unlanded_stale_is_never_deletable(self):
        """Regression: REVIEW_STALE was once emitted as DELETE_STALE and appeared
        in the auto-delete command, which would drop unlanded test coverage."""
        rows = [self._row(behind=139, verdict="REVIEW_STALE", landed=False,
                          unique_files=["old/tests/test_x.py"])]
        out = branches.render(rows, [], "master", "o/r")
        self.assertIn("REVIEW_STALE", out)
        self.assertIn("do NOT auto-delete", out)
        self.assertNotIn("git push origin --delete", out)

    def test_no_pr_is_review(self):
        rows = [self._row(pr=None, pr_state=None, verdict="REVIEW", landed=False,
                          unique_files=["x.py"])]
        out = branches.render(rows, [], "master", "o/r")
        self.assertIn("REVIEW", out)
        self.assertNotIn("git push origin --delete", out)

    def test_documented_pitfall_is_stated(self):
        out = branches.render([self._row()], [], "master", "o/r")
        self.assertIn("--is-ancestor", out)
        self.assertIn("git cherry", out)


class TestSiblingConflicts(unittest.TestCase):
    def test_shared_file_and_marker_count_pairing(self):
        rows = [
            {"branch": "old", "pr": 1, "verdict": "REVIEW", "behind": 5,
             "unique_files": ["a.py", "b.py"], "landed": False},
            {"branch": "new", "pr": 2, "verdict": "KEEP", "behind": 0,
             "unique_files": ["a.py"], "landed": False},
        ]
        with mock.patch.object(branches, "conflict_markers", return_value=3):
            pairs = branches.find_siblings(rows, "master")
        self.assertEqual(len(pairs), 1)
        self.assertEqual(pairs[0]["superseded"], "old")
        self.assertEqual(pairs[0]["by"], "new")
        self.assertEqual(pairs[0]["conflict_markers"], 3)
        self.assertEqual(pairs[0]["shared_files"], ["a.py"])

    def test_disjoint_files_produce_no_pairs(self):
        rows = [
            {"branch": "old", "pr": 1, "verdict": "REVIEW", "behind": 5,
             "unique_files": ["a.py"], "landed": False},
            {"branch": "new", "pr": 2, "verdict": "KEEP", "behind": 0,
             "unique_files": ["z.py"], "landed": False},
        ]
        self.assertEqual(branches.find_siblings(rows, "master"), [])


if __name__ == "__main__":
    unittest.main()