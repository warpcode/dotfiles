import os
import subprocess
import tempfile
import unittest

SCRIPT_PATH = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__), "..", "merge_pull_request.sh"
    )
)

class TestMergePullRequestScript(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.bin_dir = os.path.join(self.temp_dir.name, "bin")
        os.makedirs(self.bin_dir, exist_ok=True)
        self.log_file = os.path.join(self.temp_dir.name, "gh_calls.log")

    def _create_fake_gh(self, script_contents):
        gh_path = os.path.join(self.bin_dir, "gh")
        with open(gh_path, "w") as f:
            f.write("#!/bin/bash\n" + script_contents)
        os.chmod(gh_path, 0o755)

    def _run_script(self, args, env_overrides=None):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"
        env["GH_CALL_LOG"] = self.log_file
        if env_overrides:
            env.update(env_overrides)

        cmd = [SCRIPT_PATH] + args
        res = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
        )
        return res

    def _read_log(self):
        if os.path.exists(self.log_file):
            with open(self.log_file, "r") as f:
                return f.read().splitlines()
        return []

    def test_help_flag(self):
        res = self._run_script(["--help"])
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage: ./merge_pull_request.sh [OPTIONS]", res.stdout)
        self.assertIn("--merge-method, --type <squash|merge|rebase>", res.stdout)
        self.assertIn("--admin", res.stdout)

    def test_missing_required_args(self):
        res = self._run_script([])
        self.assertEqual(res.returncode, 1)
        self.assertIn("Error: --owner is required", res.stderr)

        res = self._run_script(["--owner", "foo"])
        self.assertEqual(res.returncode, 1)
        self.assertIn("Error: --repo is required", res.stderr)

        res = self._run_script(["--owner", "foo", "--repo", "bar"])
        self.assertEqual(res.returncode, 1)
        self.assertIn("Error: --pull-number is required", res.stderr)

    def test_auto_detect_branch_ruleset(self):
        fake_gh = """
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"baseRefName": "main"}'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/owner/repo/rules/branches/main" ]]; then
  echo '[{"type": "pull_request", "parameters": {"allowed_merge_methods": ["REBASE", "MERGE"]}}]'
  exit 0
fi
if [[ "$1" == "pr" && "$2" == "merge" ]]; then
  exit 0
fi
exit 0
"""
        self._create_fake_gh(fake_gh)
        res = self._run_script(["--owner", "owner", "--repo", "repo", "--pull-number", "10"])
        self.assertEqual(res.returncode, 0)
        logs = self._read_log()
        self.assertTrue(any("pr merge 10 --repo owner/repo --rebase --delete-branch" in l for l in logs))

    def test_auto_detect_repo_fallback(self):
        fake_gh = """
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"baseRefName": "main"}'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/owner/repo/rules/branches/main" ]]; then
  echo '[]'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/owner/repo" ]]; then
  echo '{"allow_squash_merge": false, "allow_merge_commit": true, "allow_rebase_merge": true}'
  exit 0
fi
if [[ "$1" == "pr" && "$2" == "merge" ]]; then
  exit 0
fi
exit 0
"""
        self._create_fake_gh(fake_gh)
        res = self._run_script(["--owner", "owner", "--repo", "repo", "--pull-number", "10"])
        self.assertEqual(res.returncode, 0)
        logs = self._read_log()
        self.assertTrue(any("pr merge 10 --repo owner/repo --merge --delete-branch" in l for l in logs))

    def test_valid_requested_merge_method_and_admin(self):
        fake_gh = """
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"baseRefName": "main"}'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/owner/repo/rules/branches/main" ]]; then
  echo '[]'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/owner/repo" ]]; then
  echo '{"allow_squash_merge": true, "allow_merge_commit": true, "allow_rebase_merge": true}'
  exit 0
fi
if [[ "$1" == "pr" && "$2" == "merge" ]]; then
  exit 0
fi
exit 0
"""
        self._create_fake_gh(fake_gh)
        res = self._run_script(["--owner", "owner", "--repo", "repo", "--pull-number", "10", "--type", "rebase", "--admin"])
        self.assertEqual(res.returncode, 0)
        logs = self._read_log()
        self.assertTrue(any("pr merge 10 --repo owner/repo --rebase --delete-branch --admin" in l for l in logs))

    def test_invalid_requested_merge_method_error_format(self):
        fake_gh = """
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"baseRefName": "main"}'
  exit 0
fi
if [[ "$1" == "api" && "$2" == "repos/owner/repo/rules/branches/main" ]]; then
  echo '[{"type": "pull_request", "parameters": {"allowed_merge_methods": ["SQUASH", "REBASE"]}}]'
  exit 0
fi
exit 0
"""
        self._create_fake_gh(fake_gh)
        res = self._run_script(["--owner", "owner", "--repo", "repo", "--pull-number", "10", "--merge-method", "merge"])
        self.assertEqual(res.returncode, 1)
        self.assertIn("Error: Merge method 'merge' is not allowed for branch 'main'. Allowed methods: squash, rebase", res.stderr)

if __name__ == "__main__":
    unittest.main()
