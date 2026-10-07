"""Tests for review-pull-request/scripts/review_worktree.sh.

Three production failure modes are pinned here:
  * inconsistent names for the same role (wt208 vs wt-main vs w200base all
    meaning "the base branch" in one session);
  * leaked worktrees when removal never ran;
  * a failed removal reported as success.
"""

import os
import subprocess
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "review_worktree.sh")
)


class WorktreeTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.repo = os.path.join(self._tmp.name, "repo")
        self.remote = os.path.join(self._tmp.name, "remote.git")
        self.root = os.path.join(self._tmp.name, "wt")
        os.makedirs(self.repo)

        self._git("init", "-q", "--bare", "-b", "main", self.remote)
        self._git("init", "-q", "-b", "main", self.repo)
        self.git("config", "user.email", "a@b")
        self.git("config", "user.name", "a")
        self.write("f.go", "l1\n")
        self.git("add", "-A")
        self.git("commit", "-qm", "base")
        self.git("remote", "add", "origin", self.remote)
        self.git("push", "-q", "origin", "main")

        # A PR-shaped ref the script can fetch.
        self.git("checkout", "-q", "-b", "feat")
        self.write("f.go", "l1\nl2\n")
        self.git("add", "-A")
        self.git("commit", "-qm", "change")
        self.git("push", "-q", "origin", "feat:refs/pull/3/head")
        self.git("checkout", "-q", "main")

    def tearDown(self):
        subprocess.run(
            ["git", "worktree", "prune"],
            cwd=self.repo, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _git(self, *args, cwd=None):
        subprocess.run(
            ["git"] + list(args), cwd=cwd or self.repo,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    def git(self, *args):
        return self._git(*args)

    def write(self, name, content):
        with open(os.path.join(self.repo, name), "w") as fh:
            fh.write(content)

    def wt(self, *args):
        # --root must precede `--`, or it would be handed to the exec'd command.
        head, sep, tail = " ".join(args).partition(" -- ")
        argv = ["bash", SCRIPT] + head.split() + ["--root", self.root]
        if sep:
            argv += ["--"] + tail.split()
        return subprocess.run(
            argv, cwd=self.repo,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    def worktrees(self):
        out = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=self.repo, stdout=subprocess.PIPE, text=True, check=True).stdout
        return [ln.split(" ", 1)[1] for ln in out.splitlines() if ln.startswith("worktree ")][1:]

    # --- creation -------------------------------------------------------------

    def test_add_head_fetches_the_pull_ref_and_prints_the_path(self):
        res = self.wt("add", "--pr", "3", "--role", "head")
        self.assertEqual(res.returncode, 0, res.stderr)
        path = res.stdout.strip()
        self.assertTrue(os.path.isdir(path), path)
        self.assertTrue(path.endswith(os.path.join("wt", "pr3-head")))
        with open(os.path.join(path, "f.go")) as fh:
            self.assertEqual(fh.read(), "l1\nl2\n")

    def test_roles_get_distinct_stable_paths(self):
        head = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        base = self.wt("add", "--pr", "3", "--role", "base").stdout.strip()
        self.assertNotEqual(head, base)
        self.assertEqual(self.wt("list", "--pr", "3").stdout.strip().split()[-1], base)

    def test_readding_a_role_does_not_create_a_second_checkout(self):
        first = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        second = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        self.assertEqual(first, second)
        self.assertEqual(len(self.worktrees()), 1)

    def test_different_prs_get_different_worktrees(self):
        self.git("push", "-q", "origin", "feat:refs/pull/4/head")
        a = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        b = self.wt("add", "--pr", "4", "--role", "head").stdout.strip()
        self.assertNotEqual(a, b)
        self.assertEqual(len(self.worktrees()), 2)

    def test_unknown_ref_is_a_usage_error(self):
        res = self.wt("add", "--pr", "3", "--role", "head", "--ref", "no-such-ref")
        self.assertEqual(res.returncode, 1)
        self.assertIn("does not exist", res.stderr)

    def test_fetch_creates_a_tracking_ref_not_a_local_branch(self):
        """Regression: a short fetch destination (`origin/pr-N`) makes git
        create refs/heads/origin/pr-N. Once the real tracking ref also exists
        the name is ambiguous and every rev-parse downstream fails."""
        self.wt("add", "--pr", "3", "--role", "head")
        out = subprocess.run(
            ["git", "show-ref"], cwd=self.repo,
            stdout=subprocess.PIPE, text=True, check=True).stdout
        self.assertNotIn("refs/heads/origin/pr-3", out)
        self.assertIn("refs/remotes/origin/pr-3", out)

    def test_ref_resolves_after_the_tracking_ref_already_exists(self):
        subprocess.run(
            ["git", "fetch", "-q", "origin",
             "+refs/pull/3/head:refs/remotes/origin/pr-3", "--force"],
            cwd=self.repo, stdout=subprocess.DEVNULL, check=True)
        path = self.wt("add", "--pr", "3", "--role", "head")
        self.assertEqual(path.returncode, 0, path.stderr)
        resolved = subprocess.run(
            ["git", "rev-parse", "origin/pr-3"], cwd=self.repo,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.assertEqual(resolved.returncode, 0, resolved.stderr)

    def test_invalid_role_is_rejected(self):
        res = self.wt("add", "--pr", "3", "--role", "bogus")
        self.assertEqual(res.returncode, 1)

    # --- exec -----------------------------------------------------------------

    def test_exec_runs_inside_the_worktree(self):
        res = self.wt("exec", "--pr", "3", "--role", "head", "--", "cat", "f.go")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(res.stdout.strip().splitlines(), ["l1", "l2"])

    def test_exec_creates_the_worktree_when_absent(self):
        res = self.wt("exec", "--pr", "3", "--role", "head", "--", "pwd")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertTrue(os.path.isdir(self.worktrees()[0]))

    # --- removal --------------------------------------------------------------

    def test_rm_all_roles_leaves_no_worktree_behind(self):
        self.wt("add", "--pr", "3", "--role", "head")
        self.wt("add", "--pr", "3", "--role", "base")
        self.assertEqual(len(self.worktrees()), 2)
        res = self.wt("rm", "--pr", "3", "--all-roles", "--force")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.worktrees(), [])

    def test_rm_all_prs_clears_every_registered_worktree(self):
        self.git("push", "-q", "origin", "feat:refs/pull/4/head")
        self.wt("add", "--pr", "3", "--role", "head")
        self.wt("add", "--pr", "4", "--role", "head")
        res = self.wt("rm", "--all-prs", "--force")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.worktrees(), [])

    def test_rm_is_idempotent(self):
        self.wt("add", "--pr", "3", "--role", "head")
        self.wt("rm", "--pr", "3", "--role", "head", "--force")
        again = self.wt("rm", "--pr", "3", "--role", "head", "--force")
        self.assertEqual(again.returncode, 0)
        self.assertEqual(self.worktrees(), [])

    def test_dirty_worktree_is_not_reported_as_removed(self):
        path = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        with open(os.path.join(path, "f.go"), "a") as fh:
            fh.write("dirty\n")
        res = self.wt("rm", "--pr", "3", "--role", "head")
        # A leaked checkout must not pass as success.
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("FAILED to remove", res.stderr)
        self.assertTrue(os.path.isdir(path))

    def test_force_removes_a_dirty_worktree(self):
        path = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        with open(os.path.join(path, "f.go"), "a") as fh:
            fh.write("dirty\n")
        res = self.wt("rm", "--pr", "3", "--role", "head", "--force")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.worktrees(), [])

    def test_registry_row_without_a_directory_is_pruned(self):
        path = self.wt("add", "--pr", "3", "--role", "head").stdout.strip()
        self.wt("rm", "--pr", "3", "--role", "head", "--force")
        # Simulate a registry row surviving a directory that was already gone.
        reg = os.path.join(self.root, ".registry")
        with open(reg, "a") as fh:
            fh.write(f"3 head {path}\n")
        res = self.wt("list", "--pr", "3")
        self.assertEqual(res.returncode, 0)
        # Header only: the stale row is gone, not listed.
        self.assertNotIn("pr3-head", res.stdout)

    # --- listing --------------------------------------------------------------

    def test_list_with_no_worktrees_says_so(self):
        res = self.wt("list")
        self.assertEqual(res.returncode, 0)
        self.assertIn("no audit worktrees", res.stdout)

    def test_list_shows_pr_role_and_path(self):
        self.wt("add", "--pr", "3", "--role", "head")
        res = self.wt("list", "--pr", "3")
        self.assertIn("3", res.stdout)
        self.assertIn("head", res.stdout)


if __name__ == "__main__":
    unittest.main()