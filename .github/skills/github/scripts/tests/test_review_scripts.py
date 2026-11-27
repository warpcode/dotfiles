"""Tests for standardized --repo owner/name flag support in github review scripts."""

import json
import os
import subprocess
import tempfile
import unittest

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SUBMIT_PAYLOAD = os.path.join(SCRIPTS_DIR, "submit_pull_request_review_payload.sh")
LIST_THREADS = os.path.join(SCRIPTS_DIR, "list_pull_request_review_threads.sh")


class ReviewScriptsFlagTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.bin_dir = os.path.join(self._tmp.name, "bin")
        os.makedirs(self.bin_dir, exist_ok=True)
        self.log_file = os.path.join(self._tmp.name, "gh.log")

        gh_stub = os.path.join(self.bin_dir, "gh")
        with open(gh_stub, "w") as fh:
            fh.write(
                """#!/usr/bin/env bash
echo "$@" >> "$GH_CALL_LOG"
if [[ "$1" == "repo" && "$2" == "view" ]]; then
  if [[ "$*" == *"owner"* ]]; then
    echo "autodetected-owner"
  else
    echo "autodetected-repo"
  fi
  exit 0
fi
if [[ "$1" == "api" && "$2" == "graphql" ]]; then
  echo '{"data":{"repository":{"pullRequest":{"number":42,"title":"Test PR","reviewThreads":{"nodes":[]}}}}}'
  exit 0
fi
if [[ "$1" == "api" ]]; then
  echo '{"html_url":"https://github.com/octocat/hello/pull/42#pullrequestreview-1","state":"COMMENTED"}'
  exit 0
fi
exit 0
"""
            )
        os.chmod(gh_stub, 0o755)

        self.payload_file = os.path.join(self._tmp.name, "payload.json")
        with open(self.payload_file, "w") as fh:
            json.dump({"event": "COMMENT", "body": "Note", "comments": []}, fh)

    def _run(self, script, args):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"
        env["GH_CALL_LOG"] = self.log_file
        return subprocess.run(
            ["bash", script] + args,
            capture_output=True,
            text=True,
            env=env,
        )

    def _read_log(self):
        if not os.path.exists(self.log_file):
            return []
        with open(self.log_file) as fh:
            return fh.read().splitlines()

    def test_submit_payload_accepts_combined_repo(self):
        res = self._run(
            SUBMIT_PAYLOAD,
            [
                "--repo",
                "octocat/hello",
                "--pull-number",
                "42",
                "--input",
                self.payload_file,
            ],
        )
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        logs = self._read_log()
        self.assertTrue(
            any("api repos/octocat/hello/pulls/42/reviews" in line for line in logs)
        )

    def test_submit_payload_rejects_conflicting_owner_and_combined_repo(self):
        res = self._run(
            SUBMIT_PAYLOAD,
            [
                "--owner",
                "octocat",
                "--repo",
                "other/hello",
                "--pull-number",
                "42",
                "--input",
                self.payload_file,
            ],
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("not both", res.stderr)

    def test_list_threads_accepts_combined_repo(self):
        res = self._run(
            LIST_THREADS,
            ["--repo", "octocat/hello", "--pull-number", "42"],
        )
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("No review threads found for PR #42", res.stdout)
        logs = self._read_log()
        self.assertTrue(
            any("-F owner=octocat -F repo=hello -F pr=42" in line for line in logs)
        )

    def test_list_threads_rejects_conflicting_owner_and_combined_repo(self):
        res = self._run(
            LIST_THREADS,
            [
                "--owner",
                "octocat",
                "--repo",
                "other/hello",
                "--pull-number",
                "42",
            ],
        )
        self.assertEqual(res.returncode, 1)
        self.assertIn("not both", res.stderr)


if __name__ == "__main__":
    unittest.main()
