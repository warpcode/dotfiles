#!/usr/bin/env python3
"""Unit and integration tests for pr_sync.sh in git-expert skill."""

import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PR_SYNC_SH = os.path.join(SCRIPTS_DIR, "pr_sync.sh")


def _git(cwd, *args):
    return subprocess.run(
        ["git", "-C", cwd, *args],
        capture_output=True,
        text=True,
        check=True,
    )


class TestPrSyncScript(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.mkdtemp(prefix="test_pr_sync_")
        self.wt_paths = []

    def tearDown(self):
        for wt_path in self.wt_paths:
            shutil.rmtree(wt_path, ignore_errors=True)
        shutil.rmtree(self.tmp_dir, ignore_errors=True)

    def _init_repo_with_origin(self, default_branch="main"):
        origin_bare = os.path.join(self.tmp_dir, "origin.git")
        subprocess.run(
            ["git", "init", "-q", "--bare", f"--initial-branch={default_branch}", origin_bare],
            check=True,
        )
        repo = os.path.join(self.tmp_dir, "repo")
        subprocess.run(["git", "init", "-q", "-b", default_branch, repo], check=True)
        _git(repo, "config", "user.name", "Test User")
        _git(repo, "config", "user.email", "test@example.com")
        _git(repo, "remote", "add", "origin", origin_bare)
        with open(os.path.join(repo, "README.md"), "w", encoding="utf-8") as f:
            f.write("initial\n")
        _git(repo, "add", "README.md")
        _git(repo, "commit", "-q", "-m", "init")
        _git(repo, "push", "-q", "-u", "origin", default_branch)
        _git(repo, "symbolic-ref", "refs/remotes/origin/HEAD", f"refs/remotes/origin/{default_branch}")
        return repo, origin_bare

    def test_help_does_not_advertise_hardcoded_origin_master(self):
        res = subprocess.run([PR_SYNC_SH, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("--base <ref>", res.stdout)
        self.assertNotIn("origin/master", res.stdout)

    def test_default_base_resolves_origin_head_main_and_syncs(self):
        repo, origin_bare = self._init_repo_with_origin("main")
        branch = f"feat/sync-main-{os.getpid()}"
        self.wt_paths.append(f"/tmp/wt-{branch.replace('/', '-')}")

        _git(repo, "checkout", "-q", "-b", branch)
        with open(os.path.join(repo, "feature.txt"), "w", encoding="utf-8") as f:
            f.write("feature work\n")
        _git(repo, "add", "feature.txt")
        _git(repo, "commit", "-q", "-m", "feature commit")
        _git(repo, "push", "-q", "origin", branch)

        # Advance main in a separate clone so local origin/main is stale
        adv = os.path.join(self.tmp_dir, "adv")
        subprocess.run(["git", "clone", "-q", origin_bare, adv], check=True)
        _git(adv, "config", "user.name", "Test User")
        _git(adv, "config", "user.email", "test@example.com")
        _git(adv, "checkout", "-q", "main")
        with open(os.path.join(adv, "main_update.txt"), "w", encoding="utf-8") as f:
            f.write("from main\n")
        _git(adv, "add", "main_update.txt")
        _git(adv, "commit", "-q", "-m", "main advances")
        _git(adv, "push", "-q", "origin", "main")

        _git(repo, "checkout", "-q", "main")
        res = subprocess.run(
            [PR_SYNC_SH, branch],
            cwd=repo,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout={res.stdout}\nstderr={res.stderr}")
        self.assertIn("Attempting to merge origin/main", res.stdout)

        # Verify remote PR branch now includes main_update.txt
        _git(repo, "fetch", "-q", "origin", branch)
        ls_tree = _git(repo, "ls-tree", "--name-only", f"origin/{branch}").stdout.splitlines()
        self.assertIn("main_update.txt", ls_tree)
        self.assertIn("feature.txt", ls_tree)

    def test_non_origin_remote_base_is_fetched_before_merge(self):
        repo, _ = self._init_repo_with_origin("main")
        upstream_bare = os.path.join(self.tmp_dir, "upstream.git")
        subprocess.run(["git", "init", "-q", "--bare", "--initial-branch=main", upstream_bare], check=True)
        _git(repo, "remote", "add", "upstream", upstream_bare)
        _git(repo, "push", "-q", "upstream", "main")
        _git(repo, "fetch", "-q", "upstream", "main")

        branch = f"feat/sync-upstream-{os.getpid()}"
        self.wt_paths.append(f"/tmp/wt-{branch.replace('/', '-')}")

        _git(repo, "checkout", "-q", "-b", branch)
        with open(os.path.join(repo, "pr.txt"), "w", encoding="utf-8") as f:
            f.write("pr change\n")
        _git(repo, "add", "pr.txt")
        _git(repo, "commit", "-q", "-m", "pr change")
        _git(repo, "push", "-q", "origin", branch)

        # Advance upstream/main without fetching in repo
        adv = os.path.join(self.tmp_dir, "adv_upstream")
        subprocess.run(["git", "clone", "-q", upstream_bare, adv], check=True)
        _git(adv, "config", "user.name", "Test User")
        _git(adv, "config", "user.email", "test@example.com")
        with open(os.path.join(adv, "upstream_only.txt"), "w", encoding="utf-8") as f:
            f.write("upstream commit\n")
        _git(adv, "add", "upstream_only.txt")
        _git(adv, "commit", "-q", "-m", "upstream advance")
        _git(adv, "push", "-q", "origin", "main")

        _git(repo, "checkout", "-q", "main")
        res = subprocess.run(
            [PR_SYNC_SH, branch, "--base", "upstream/main"],
            cwd=repo,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout={res.stdout}\nstderr={res.stderr}")
        _git(repo, "fetch", "-q", "origin", branch)
        ls_tree = _git(repo, "ls-tree", "--name-only", f"origin/{branch}").stdout.splitlines()
        self.assertIn("upstream_only.txt", ls_tree)

    def test_slashed_local_base_does_not_attempt_remote_fetch(self):
        repo, _ = self._init_repo_with_origin("main")
        _git(repo, "checkout", "-q", "-b", "epic/402-demo")
        with open(os.path.join(repo, "epic.txt"), "w", encoding="utf-8") as f:
            f.write("epic commit\n")
        _git(repo, "add", "epic.txt")
        _git(repo, "commit", "-q", "-m", "epic commit")

        branch = f"issue/sub-sync-{os.getpid()}"
        self.wt_paths.append(f"/tmp/wt-{branch.replace('/', '-')}")
        _git(repo, "checkout", "-q", "-b", branch, "main")
        with open(os.path.join(repo, "sub.txt"), "w", encoding="utf-8") as f:
            f.write("sub work\n")
        _git(repo, "add", "sub.txt")
        _git(repo, "commit", "-q", "-m", "sub commit")
        _git(repo, "push", "-q", "origin", branch)

        _git(repo, "checkout", "-q", "main")
        res = subprocess.run(
            [PR_SYNC_SH, branch, "--base", "epic/402-demo"],
            cwd=repo,
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 0, msg=f"stdout={res.stdout}\nstderr={res.stderr}")
        _git(repo, "fetch", "-q", "origin", branch)
        ls_tree = _git(repo, "ls-tree", "--name-only", f"origin/{branch}").stdout.splitlines()
        self.assertIn("epic.txt", ls_tree)
        self.assertIn("sub.txt", ls_tree)


if __name__ == "__main__":
    unittest.main()
