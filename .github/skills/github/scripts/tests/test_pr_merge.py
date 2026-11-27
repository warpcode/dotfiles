"""Tests for github/scripts/pr_merge.sh."""

import os
import subprocess
import tempfile
import unittest

SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "pr_merge.sh"))

# A gh stub whose `pr view` prints a hint on stderr (as gh >= 2.106 does) alongside the JSON
# payload on stdout. Any stderr captured into the JSON variable breaks jq parsing.
GH_STUB = """#!/usr/bin/env bash
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  if [[ "${GH_STUB_FAIL:-0}" == "1" ]]; then
    echo "boom: could not resolve to a PullRequest" >&2
    exit 1
  fi
  echo "hint: if you need to wait for this pull request, use gh event listen instead of polling" >&2
  echo '{"number":42,"title":"Test PR","state":"OPEN","mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","headRefName":"feature/x","baseRefName":"master","statusCheckRollup":[{"name":"ci","status":"COMPLETED","conclusion":"SUCCESS"}]}'
  exit 0
fi
exit 0
"""


class TestPrMergeScript(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.bin_dir = os.path.join(self.temp_dir.name, "bin")
        os.makedirs(self.bin_dir, exist_ok=True)
        self.log_file = os.path.join(self.temp_dir.name, "gh_calls.log")

        gh_stub = os.path.join(self.bin_dir, "gh")
        with open(gh_stub, "w") as f:
            f.write(GH_STUB)
        os.chmod(gh_stub, 0o755)

    def _run(self, args, extra_env=None):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"
        env["GH_CALL_LOG"] = self.log_file
        env.update(extra_env or {})
        return subprocess.run(
            ["bash", SCRIPT_PATH] + args,
            capture_output=True,
            text=True,
            env=env,
        )

    def test_stderr_hint_does_not_corrupt_json_preflight(self):
        res = self._run(["42", "--repo", "octocat/hello", "--dry-run"])
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("CI Checks: Passed (1 checks verified)", res.stdout)
        self.assertNotIn("jq: parse error", res.stderr)

    def test_gh_failure_still_reports_stderr_detail(self):
        res = self._run(["42", "--repo", "octocat/hello", "--dry-run"], {"GH_STUB_FAIL": "1"})
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertIn("could not resolve to a PullRequest", res.stderr)


if __name__ == "__main__":
    unittest.main()
