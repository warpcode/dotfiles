"""Tests for review-pull-request/scripts/pr_preflight.sh.

The script exists so the diff and the head ref cannot come from different
moments. These tests pin the two behaviours that make that true: one fetch
produces both artefacts, and a moved head is a hard failure (exit 3) rather
than a silent pass.
"""

import json
import os
import subprocess
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "pr_preflight.sh")
)

# Stub `gh`: the script must never reach the network in a test.
GH_STUB = """#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "diff" ]]; then
  cat <<'DIFF'
diff --git a/f.go b/f.go
--- a/f.go
+++ b/f.go
@@ -1,1 +1,2 @@
 keep
+added
DIFF
  exit 0
fi
echo "gh stub: unexpected args: $*" >&2
exit 1
"""


class PreflightTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.base = self._tmp.name
        self.repo = os.path.join(self.base, "repo")
        self.remote = os.path.join(self.base, "remote.git")
        self.out = os.path.join(self.base, "out")
        self.bin = os.path.join(self.base, "bin")
        os.makedirs(self.repo)
        os.makedirs(self.bin)

        gh = os.path.join(self.bin, "gh")
        with open(gh, "w") as fh:
            fh.write(GH_STUB)
        os.chmod(gh, 0o755)

        self._git("init", "-q", "--bare", "-b", "main", self.remote)
        self._git("init", "-q", "-b", "main", self.repo)
        self.git("config", "user.email", "a@b")
        self.git("config", "user.name", "a")
        self.write("f.go", "keep\n")
        self.git("add", "-A")
        self.git("commit", "-qm", "base")
        self.git("remote", "add", "origin", self.remote)
        self.git("push", "-q", "origin", "main")
        self.git("checkout", "-q", "-b", "feat")
        self.write("f.go", "keep\nadded\n")
        self.git("add", "-A")
        self.git("commit", "-qm", "change")
        self.git("push", "-q", "origin", "feat:refs/pull/5/head")
        self.git("checkout", "-q", "main")
        self.head_sha = subprocess.run(
            ["git", "rev-parse", "feat"], cwd=self.repo,
            stdout=subprocess.PIPE, text=True, check=True).stdout.strip()

    def _git(self, *args, cwd=None):
        subprocess.run(["git"] + list(args), cwd=cwd or self.repo,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    def git(self, *args):
        return self._git(*args)

    def write(self, name, content):
        with open(os.path.join(self.repo, name), "w") as fh:
            fh.write(content)

    def preflight(self, *args):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin}:{env['PATH']}"
        return subprocess.run(
            ["bash", SCRIPT, *args],
            cwd=self.repo, env=env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    def manifest(self):
        with open(os.path.join(self.out, "manifest.json")) as fh:
            return json.load(fh)

    # --- capture --------------------------------------------------------------

    def test_writes_manifest_and_diff(self):
        res = self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out)
        self.assertEqual(res.returncode, 0, res.stderr)
        m = self.manifest()
        self.assertEqual(m["repo"], "o/r")
        self.assertEqual(m["pr"], 5)
        self.assertEqual(m["head_sha"], self.head_sha)
        self.assertEqual(m["files"], 1)
        self.assertTrue(os.path.exists(m["diff"]))
        with open(m["diff"]) as fh:
            self.assertIn("+added", fh.read())

    def test_fetches_the_pull_ref_under_a_predictable_name(self):
        self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out)
        exists = subprocess.run(
            ["git", "rev-parse", "--verify", "-q", "origin/pr-5"],
            cwd=self.repo, stdout=subprocess.DEVNULL).returncode
        self.assertEqual(exists, 0)

    def test_does_not_create_a_local_branch_named_origin_slash_pr(self):
        """Regression: `git fetch origin +refs/pull/N/head:origin/pr-N` makes
        git create the LOCAL BRANCH refs/heads/origin/pr-N, not the
        remote-tracking ref. Once both exist, `origin/pr-N` is ambiguous and
        every downstream `git rev-parse` / `--head` cross-check fails."""
        self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out)
        out = subprocess.run(
            ["git", "show-ref"], cwd=self.repo,
            stdout=subprocess.PIPE, text=True, check=True).stdout
        self.assertNotIn("refs/heads/origin/pr-5", out)
        self.assertIn("refs/remotes/origin/pr-5", out)

    def test_head_ref_stays_unambiguous_when_the_tracking_ref_also_exists(self):
        """The realistic sequence: something else already fetched
        refs/remotes/origin/pr-N, then the script runs. The manifest's ref must
        still resolve."""
        subprocess.run(
            ["git", "fetch", "-q", "origin",
             "+refs/pull/5/head:refs/remotes/origin/pr-5", "--force"],
            cwd=self.repo, stdout=subprocess.DEVNULL, check=True)
        res = self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out, "--json")
        self.assertEqual(res.returncode, 0, res.stderr)
        # rev-parse must succeed without the "ambiguous" error.
        resolved = subprocess.run(
            ["git", "rev-parse", "origin/pr-5"], cwd=self.repo,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.assertEqual(resolved.returncode, 0, resolved.stderr)
        self.assertEqual(resolved.stdout.strip(), self.head_sha)

    def test_json_mode_emits_the_manifest(self):
        res = self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out, "--json")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(json.loads(res.stdout)["head_sha"], self.head_sha)

    def test_prints_the_next_commands(self):
        res = self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out)
        self.assertIn("verify_review_anchors.sh", res.stdout)
        self.assertIn("submit_review.sh", res.stdout)

    # --- moved head -----------------------------------------------------------

    def test_matching_expect_sha_passes(self):
        res = self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out,
                             "--expect-sha", self.head_sha)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("head unchanged", res.stdout)

    def test_moved_head_fails_with_exit_3(self):
        """A bot PR amended mid-audit. Exiting 0 here would let a review be
        submitted against anchors derived from a superseded diff."""
        res = self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out,
                             "--expect-sha", "0" * 40)
        self.assertEqual(res.returncode, 3, res.stdout + res.stderr)
        self.assertIn("HEAD MOVED", res.stdout)
        self.assertIn("Re-run the audit", res.stdout)

    def test_moved_head_still_writes_the_fresh_manifest(self):
        self.preflight("--repo", "o/r", "--pr", "5", "--out", self.out,
                       "--expect-sha", "0" * 40)
        self.assertEqual(self.manifest()["head_sha"], self.head_sha)

    # --- usage ----------------------------------------------------------------

    def test_repo_is_required(self):
        res = self.preflight("--pr", "5")
        self.assertEqual(res.returncode, 1)
        self.assertIn("--repo is required", res.stderr)

    def test_pr_is_required(self):
        res = self.preflight("--repo", "o/r")
        self.assertEqual(res.returncode, 1)
        self.assertIn("--pr is required", res.stderr)

    def test_unknown_argument_is_rejected(self):
        res = self.preflight("--repo", "o/r", "--pr", "5", "--nope")
        self.assertEqual(res.returncode, 1)
        self.assertIn("unknown argument", res.stderr)

    def test_unfetchable_pull_ref_is_an_error_not_an_empty_manifest(self):
        res = self.preflight("--repo", "o/r", "--pr", "999", "--out", self.out)
        self.assertEqual(res.returncode, 1)
        self.assertFalse(os.path.exists(os.path.join(self.out, "manifest.json")))


if __name__ == "__main__":
    unittest.main()