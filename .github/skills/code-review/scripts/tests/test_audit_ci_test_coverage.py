"""Tests for review-pull-request/scripts/audit_ci_test_coverage.sh.

Two behaviours matter:

* correctness of the verdict -- "NO test file is named in any workflow" is the
  finding that makes a PR's "all tests pass" body claim unfalsifiable, and it
  fired on warpcode/dotfiles#142 where a new injection regression test was
  never executed by any workflow;
* the workflow-body cache. The original implementation called `file_body` (one
  `git show`) inside a workflows x tests loop, so 20 workflows x 800 test files
  meant 16,000 `git show` invocations and ~45s. That is pinned here by counting
  `git show` calls rather than by timing, which would be flaky.
"""

import os
import subprocess
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "audit_ci_test_coverage.sh")
)


class CiCoverageTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.repo = os.path.join(self._tmp.name, "repo")
        self.remote = os.path.join(self._tmp.name, "remote.git")
        os.makedirs(self.repo)
        self._git("init", "-q", "--bare", "-b", "main", self.remote)
        self._git("init", "-q", "-b", "main", self.repo)
        self.git("config", "user.email", "a@b")
        self.git("config", "user.name", "a")
        self.git("remote", "add", "origin", self.remote)

    def _git(self, *args):
        return subprocess.run(
            ["git"] + list(args), cwd=self.repo,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    def git(self, *args):
        return subprocess.run(
            ["git"] + list(args), cwd=self.repo,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    def write(self, name, content):
        path = os.path.join(self.repo, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as fh:
            fh.write(content)

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "-qm", "snapshot")

    def run_script(self, *args, count_git_show=False):
        """Run the auditor. When count_git_show, put a counting `git` shim on
        PATH so we can assert the workflow bodies are read once each."""
        env = os.environ.copy()
        if count_git_show:
            shim_dir = os.path.join(self._tmp.name, "shim")
            os.makedirs(shim_dir, exist_ok=True)
            log = os.path.join(self._tmp.name, "git-show.log")
            real_git = subprocess.run(["which", "git"], stdout=subprocess.PIPE,
                                      text=True, check=True).stdout.strip()
            with open(os.path.join(shim_dir, "git"), "w") as fh:
                fh.write(
                    "#!/usr/bin/env bash\n"
                    f'if [[ "$1" == "show" ]]; then echo "$@" >> {log}; fi\n'
                    f'exec {real_git} "$@"\n'
                )
            os.chmod(os.path.join(shim_dir, "git"), 0o755)
            env["PATH"] = f"{shim_dir}:{env['PATH']}"
        res = subprocess.run(
            ["bash", SCRIPT, *args], cwd=self.repo, env=env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        shows = []
        log = os.path.join(self._tmp.name, "git-show.log")
        if count_git_show and os.path.exists(log):
            with open(log) as fh:
                shows = [ln for ln in fh.read().splitlines() if ln.strip()]
        return res, shows

    def workflow(self, name, body):
        self.write(f".github/workflows/{name}", body)

    # --- verdicts -------------------------------------------------------------

    def test_reports_when_no_workflow_names_a_test(self):
        for i in range(3):
            self.write(f"tests/test_{i}.py", "def test_x(): pass\n")
        self.workflow("ci.yml", "name: ci\njobs:\n  t:\n    steps:\n      - run: true\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("NO test file is named in any workflow", res.stdout)

    def test_reports_a_referenced_test_and_which_workflow_names_it(self):
        self.write("tests/test_a.py", "def test_x(): pass\n")
        self.write("tests/test_b.py", "def test_y(): pass\n")
        self.workflow("ci.yml",
                      "name: ci\njobs:\n  t:\n    steps:\n"
                      "      - run: python3 -m pytest tests/test_a.py\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD")
        self.assertIn("REFERENCED  tests/test_a.py", res.stdout)
        self.assertIn("ci.yml", res.stdout)
        self.assertNotIn("NO test file is named in any workflow", res.stdout)

    def test_detects_test_runner_invocations(self):
        self.write("tests/test_a.py", "def test_x(): pass\n")
        self.workflow("ci.yml",
                      "name: ci\njobs:\n  t:\n    steps:\n"
                      "      - run: python3 -m pytest\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD")
        self.assertIn("test invocations found in workflows", res.stdout)
        self.assertIn("pytest", res.stdout)

    def test_reports_no_test_files_when_there_are_none(self):
        self.workflow("ci.yml", "name: ci\njobs:\n  t:\n    steps:\n      - run: true\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("No test files detected", res.stdout)

    def test_requested_paths_report_reference_status(self):
        self.write("tests/test_a.py", "def test_x(): pass\n")
        self.workflow("ci.yml",
                      "name: ci\njobs:\n  t:\n    steps:\n"
                      "      - run: python3 -m pytest tests/test_a.py\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD", "tests/test_a.py", "tests/test_zz.py")
        self.assertIn("referenced-by-ci: yes", res.stdout)
        self.assertIn("not a detected test file", res.stdout)

    def test_path_filters_are_reported(self):
        self.write("tests/test_a.py", "def test_x(): pass\n")
        self.workflow("ci.yml",
                      "name: ci\njobs:\n  t:\n    steps:\n"
                      "      - run: python3 -m pytest\n"
                      "    if:\n      paths:\n        - '**/*.py'\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD")
        self.assertIn("path filters", res.stdout)
        self.assertIn("**/*.py", res.stdout)

    # --- the caching regression ----------------------------------------------

    def test_missing_origin_reports_a_diagnostic_instead_of_aborting(self):
        """Regression: `repo=$(git remote get-url origin | sed ...)` under
        `set -euo pipefail` aborted with exit 2 and no output when the repo had
        no `origin` remote, so the intended "pass --repo" hint never printed."""
        self.git("remote", "remove", "origin")
        self.write("tests/test_a.py", "def test_x(): pass\n")
        self.commit()
        res, _ = self.run_script("--ref", "HEAD")
        self.assertEqual(res.returncode, 1)
        self.assertIn("pass --repo", res.stderr)

    def test_workflow_bodies_are_read_once_each(self):
        """Regression: file_body ran inside the workflows x tests loop, so the
        cost was O(workflows x tests) `git show` calls -- 16,000 for a repo with
        20 workflows and 800 test files."""
        n_workflows, n_tests = 6, 40
        for i in range(n_workflows):
            self.workflow(f"ci{i}.yml",
                          f"name: ci{i}\njobs:\n  t:\n    steps:\n      - run: echo {i}\n")
        for i in range(n_tests):
            self.write(f"tests/test_{i}.py", "def test_x(): pass\n")
        self.commit()

        _, shows = self.run_script("--ref", "HEAD", count_git_show=True)
        # One `git show` per workflow body, read once. The old code issued
        # n_workflows * n_tests.
        self.assertLessEqual(
            len(shows), n_workflows * 2,
            f"expected O(workflows) git show calls, got {len(shows)}",
        )

    def test_large_repo_completes_promptly(self):
        """Wall-clock guard on the same regression. Generous enough to survive
        a loaded CI runner, tight enough to catch a 45s regression."""
        import time
        for i in range(8):
            self.workflow(f"ci{i}.yml",
                          f"name: ci{i}\njobs:\n  t:\n    steps:\n      - run: echo {i}\n")
        for i in range(400):
            self.write(f"tests/test_{i}.py", "def test_x(): pass\n")
        self.commit()
        start = time.monotonic()
        res, _ = self.run_script("--ref", "HEAD")
        elapsed = time.monotonic() - start
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertLess(elapsed, 15, f"took {elapsed:.1f}s -- caching regressed")


if __name__ == "__main__":
    unittest.main()