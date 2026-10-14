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


class TestResolveBaseBranch(unittest.TestCase):
    def test_explicit_branch_kept(self):
        self.assertEqual(branches.resolve_base_branch("develop"), "develop")

    def test_explicit_origin_prefix_stripped(self):
        self.assertEqual(branches.resolve_base_branch("origin/main"), "main")
        self.assertEqual(branches.resolve_base_branch("origin/master"), "master")

    def test_symbolic_ref_origin_head_resolved(self):
        with mock.patch.object(branches, "run",
                               return_value=(0, "origin/main\n", "")):
            self.assertEqual(branches.resolve_base_branch(None), "main")

    def test_fallback_to_main_if_exists(self):
        with mock.patch.object(branches, "run", return_value=(1, "", "")), \
             mock.patch.object(branches, "rev", side_effect=lambda ref: "sha" if ref == "origin/main" else None):
            self.assertEqual(branches.resolve_base_branch(None), "main")

    def test_fallback_to_master_if_main_absent(self):
        with mock.patch.object(branches, "run", return_value=(1, "", "")), \
             mock.patch.object(branches, "rev", side_effect=lambda ref: "sha" if ref == "origin/master" else None):
            self.assertEqual(branches.resolve_base_branch(None), "master")


class TestBlobComparison(unittest.TestCase):
    def setUp(self):
        branches.clear_caches()

    def test_blob_returns_oid(self):
        with mock.patch.object(branches, "run", return_value=(0, "abc123\n", "")):
            self.assertEqual(branches.blob("origin/master", "a.py"), "abc123")

    def test_blob_none_when_path_absent(self):
        with mock.patch.object(branches, "run", return_value=(1, "", "")):
            self.assertIsNone(branches.blob("origin/master", "gone.py"))


class TestCachingAndOptimization(unittest.TestCase):
    def setUp(self):
        branches.clear_caches()

    def test_blob_caches_results(self):
        with mock.patch.object(branches, "run", return_value=(0, "oid123\n", "")) as mock_run:
            res1 = branches.blob("ref1", "f.txt")
            res2 = branches.blob("ref1", "f.txt")
            self.assertEqual(res1, "oid123")
            self.assertEqual(res2, "oid123")
            self.assertEqual(mock_run.call_count, 1)

    def test_merge_base_is_symmetric_and_cached(self):
        with mock.patch.object(branches, "run", return_value=(0, "sha123\n", "")) as mock_run:
            mb1 = branches.merge_base("origin/b1", "origin/b2")
            mb2 = branches.merge_base("origin/b2", "origin/b1")
            self.assertEqual(mb1, "sha123")
            self.assertEqual(mb2, "sha123")
            self.assertEqual(mock_run.call_count, 1)

    def test_conflict_markers_symmetric_and_cached(self):
        with mock.patch.object(branches, "run", side_effect=[(0, "mb123", ""), (0, "<<<<<<<\n<<<<<<<", "")]):
            cm1 = branches.conflict_markers("origin/a", "origin/b")
            cm2 = branches.conflict_markers("origin/b", "origin/a")
            self.assertEqual(cm1, 2)
            self.assertEqual(cm2, 2)

    def test_clear_caches_resets_state(self):
        with mock.patch.object(branches, "run", return_value=(0, "oid1\n", "")) as mock_run:
            branches.blob("ref", "f")
            self.assertEqual(mock_run.call_count, 1)
            branches.clear_caches()
            branches.blob("ref", "f")
            self.assertEqual(mock_run.call_count, 2)


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

    def test_competing_open_prs_are_paired(self):
        """Regression: sibling detection only paired dead-vs-live branches, so
        two OPEN PRs touching the same file were structurally invisible. That is
        the common case -- on 2026-10-10 #180 and #181 were both open and
        carried a byte-identical server.py."""
        rows = [
            {"branch": "sentinel/x", "pr": 180, "verdict": "KEEP", "behind": 0,
             "unique_files": ["server.py", ".jules/sentinel.md"], "landed": False},
            {"branch": "tools/y", "pr": 181, "verdict": "KEEP", "behind": 0,
             "unique_files": ["server.py", "new_tool.py"], "landed": False},
        ]
        with mock.patch.object(branches, "conflict_markers", return_value=1), \
             mock.patch.object(branches, "identical_blobs", return_value=["server.py"]):
            pairs = branches.find_siblings(rows, "master")
        self.assertEqual(len(pairs), 1, "competing OPEN PRs must be paired")
        self.assertEqual(pairs[0]["superseded_pr"], 180)
        self.assertEqual(pairs[0]["by_pr"], 181)
        self.assertEqual(pairs[0]["identical_files"], ["server.py"])

    def test_open_pair_reported_once_not_twice(self):
        """The unordered pair (A,B) must not also appear as (B,A)."""
        rows = [
            {"branch": "a", "pr": 1, "verdict": "KEEP", "behind": 0,
             "unique_files": ["f.py"], "landed": False},
            {"branch": "b", "pr": 2, "verdict": "KEEP", "behind": 0,
             "unique_files": ["f.py"], "landed": False},
        ]
        with mock.patch.object(branches, "conflict_markers", return_value=0), \
             mock.patch.object(branches, "identical_blobs", return_value=["f.py"]):
            pairs = branches.find_siblings(rows, "master")
        self.assertEqual(len(pairs), 1)
        self.assertEqual({pairs[0]["superseded"], pairs[0]["by"]}, {"a", "b"})


class TestPrFetchRefsNotBranches(unittest.TestCase):
    """`pr-<n>` refs are created by pr_audit_bundle.sh, not by a human branch."""

    def test_pr_refs_are_excluded(self):
        refs = ("origin/master\norigin/main\norigin/HEAD\n"
                "origin/pr-178\norigin/pr-181\n"
                "origin/bolt/registry-reply-nofork\n")
        with mock.patch.object(branches, "run", return_value=(0, refs, "")):
            names = branches.list_branches()
        self.assertNotIn("pr-178", names)
        self.assertNotIn("pr-181", names)
        self.assertIn("bolt/registry-reply-nofork", names)

    def test_real_branch_containing_digits_survives(self):
        """Only the exact `pr-<n>` shape is dropped, not legitimate names."""
        refs = "origin/pr-181-hotfix\norigin/feature/pr-9\norigin/pricing-tool\n"
        with mock.patch.object(branches, "run", return_value=(0, refs, "")):
            names = branches.list_branches()
        self.assertEqual(names, ["feature/pr-9", "pr-181-hotfix", "pricing-tool"])


if __name__ == "__main__":
    unittest.main()
