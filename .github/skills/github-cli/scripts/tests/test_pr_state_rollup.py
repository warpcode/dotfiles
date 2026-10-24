import unittest
import sys
from pathlib import Path
from unittest.mock import patch

# Add script directory to sys.path
script_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(script_dir))

import pr_state_rollup as prs


class TestPRStateRollup(unittest.TestCase):
    def test_resolve_repo_explicit(self):
        self.assertEqual(prs.resolve_repo("explicit/repo"), "explicit/repo")

    @patch("pr_state_rollup.run")
    def test_resolve_repo_git_remote_ssh(self, mock_run):
        mock_run.return_value = (0, "git@github.com:owner/repo.git\n", "")
        self.assertEqual(prs.resolve_repo(None), "owner/repo")
        mock_run.assert_called_once_with(["git", "remote", "get-url", "origin"])

    @patch("pr_state_rollup.run")
    def test_resolve_repo_git_remote_https(self, mock_run):
        mock_run.return_value = (0, "https://github.com/owner/repo\n", "")
        self.assertEqual(prs.resolve_repo(None), "owner/repo")

    @patch("sys.stderr.write")
    @patch("pr_state_rollup.run")
    def test_resolve_repo_git_remote_failure(self, mock_run, mock_stderr):
        mock_run.return_value = (1, "", "fatal: not a git repository")
        with self.assertRaises(SystemExit) as cm:
            prs.resolve_repo(None)
        self.assertEqual(cm.exception.code, 1)
        mock_stderr.assert_called()

    @patch("sys.stderr.write")
    @patch("pr_state_rollup.run")
    def test_resolve_repo_git_remote_unparseable(self, mock_run, mock_stderr):
        mock_run.return_value = (0, "https://gitlab.com/owner/repo.git\n", "")
        with self.assertRaises(SystemExit) as cm:
            prs.resolve_repo(None)
        self.assertEqual(cm.exception.code, 1)
        mock_stderr.assert_called()

    def test_rollup_status_empty(self):
        pr = {"statusCheckRollup": []}
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.NONE)
        self.assertEqual(failing, "")
        self.assertEqual(pending, "")

    def test_rollup_status_success(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "SUCCESS", "name": "build"},
                {"state": "neutral", "context": "linter"},
                {"status": "SKIPPED", "name": "docs"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.OK)
        self.assertEqual(failing, "")
        self.assertEqual(pending, "")

    def test_rollup_status_failure(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "SUCCESS", "name": "build"},
                {"conclusion": "FAILURE", "name": "test"},
                {"status": "in_progress", "name": "deploy"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.FAIL)
        self.assertEqual(failing, "test")
        self.assertEqual(pending, "")

    def test_rollup_status_pending(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "SUCCESS", "name": "build"},
                {"status": "IN_PROGRESS", "name": "test"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.PENDING)
        self.assertEqual(failing, "")
        self.assertEqual(pending, "test")

    def test_rollup_status_missing_and_none(self):
        # Missing key
        self.assertEqual(prs.rollup_status({}), (prs.NONE, "", ""))
        # None value
        self.assertEqual(prs.rollup_status({"statusCheckRollup": None}), (prs.NONE, "", ""))

    def test_rollup_status_multiple_failing_and_pending(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "FAILURE", "name": "lint"},
                {"conclusion": "ERROR", "name": "test"},
                {"status": "IN_PROGRESS", "name": "deploy"},
                {"status": "QUEUED", "name": "docs"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.FAIL)
        self.assertEqual(failing, "lint,test")
        self.assertEqual(pending, "")

    def test_rollup_status_multiple_pending_only(self):
        pr = {
            "statusCheckRollup": [
                {"status": "IN_PROGRESS", "name": "deploy"},
                {"status": "QUEUED", "name": "docs"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.PENDING)
        self.assertEqual(failing, "")
        self.assertEqual(pending, "deploy,docs")

    def test_rollup_status_name_fallbacks(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "FAILURE", "name": "explicit_name"},
                {"conclusion": "FAILURE", "context": "context_name"},
                {"conclusion": "FAILURE"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.FAIL)
        self.assertEqual(failing, "explicit_name,context_name,?")

    def test_rollup_status_state_fallbacks(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "FAILURE", "state": "SUCCESS", "status": "PENDING", "name": "c1"},
                {"state": "FAILURE", "status": "SUCCESS", "name": "c2"},
                {"status": "FAILURE", "name": "c3"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.FAIL)
        self.assertEqual(failing, "c1,c2,c3")

    def test_rollup_status_all_fail_and_pending_states(self):
        for state in prs.FAIL_STATES:
            pr = {"statusCheckRollup": [{"state": state, "name": "check"}]}
            overall, failing, pending = prs.rollup_status(pr)
            self.assertEqual(overall, prs.FAIL, f"Failed for fail state: {state}")
            self.assertEqual(failing, "check")

        for state in prs.PENDING_STATES:
            pr = {"statusCheckRollup": [{"state": state, "name": "check"}]}
            overall, failing, pending = prs.rollup_status(pr)
            self.assertEqual(overall, prs.PENDING, f"Failed for pending state: {state}")
            self.assertEqual(pending, "check")

    def test_rollup_status_unknown_state(self):
        pr = {
            "statusCheckRollup": [
                {"conclusion": "SUCCESS", "name": "build"},
                {"state": "UNKNOWN_CUSTOM_STATE", "name": "custom_check"},
            ]
        }
        overall, failing, pending = prs.rollup_status(pr)
        self.assertEqual(overall, prs.OK)
        self.assertEqual(failing, "")
        self.assertEqual(pending, "")

    def test_attention_reasons(self):
        pr = {
            "number": 101,
            "mergeable": "CONFLICTING",
            "isDraft": True,
            "headRefOid": "abcdef123456",
            "statusCheckRollup": [{"conclusion": "FAILURE", "name": "ci"}],
        }
        expect = {101: "1234567"}
        reasons = prs.attention_reasons(pr, expect)
        self.assertIn("CONFLICTING", reasons)
        self.assertIn("checks failing: ci", reasons)
        self.assertIn("draft", reasons)
        self.assertTrue(any("HEAD DRIFT" in r for r in reasons))

    def test_attention_reasons_precomputed(self):
        pr = {
            "number": 102,
            "mergeable": "MERGEABLE",
            "isDraft": False,
            "headRefOid": "abcdef123456",
        }
        expect = {}
        # Precomputed failure bypasses rollup_status(pr) lookup
        reasons_fail = prs.attention_reasons(pr, expect, overall=prs.FAIL, failing="lint,test")
        self.assertEqual(reasons_fail, ["checks failing: lint,test"])

        # Precomputed ok bypasses rollup_status(pr) lookup
        reasons_ok = prs.attention_reasons(pr, expect, overall=prs.OK, failing="")
        self.assertEqual(reasons_ok, [])

    def test_wait_loop_bounded_sleep(self):
        # Verify that sleeping in wait loop does not exceed remaining time before deadline
        import time
        from unittest.mock import patch, MagicMock

        mock_pr = {
            "number": 1,
            "statusCheckRollup": [{"status": "IN_PROGRESS", "name": "build"}],
        }

        # Setup mock args for main()
        test_args = ["pr_state_rollup.py", "--repo", "owner/repo", "--wait", "--timeout", "10", "--interval", "20"]

        slept_durations = []

        def fake_sleep(seconds):
            slept_durations.append(seconds)

        # Mock time.time to advance by slept_durations or fixed increments
        curr_time = 1000.0

        def fake_time():
            nonlocal curr_time
            return curr_time

        def fake_sleep_advance(seconds):
            nonlocal curr_time
            slept_durations.append(seconds)
            curr_time += seconds

        with patch.object(sys, "argv", test_args), \
             patch("pr_state_rollup.resolve_repo", return_value="owner/repo"), \
             patch("pr_state_rollup.fetch", return_value=[mock_pr]), \
             patch("time.time", side_effect=fake_time), \
             patch("time.sleep", side_effect=fake_sleep_advance), \
             patch("sys.stderr.write"):
            with self.assertRaises(SystemExit):
                prs.main()

        # The interval is 20s, but timeout is 10s. Time remaining was 10s.
        # Slept duration should be capped at 10s (the remaining time until deadline).
        self.assertEqual(len(slept_durations), 1)
        self.assertAlmostEqual(slept_durations[0], 10.0, places=4)

    def test_render(self):
        prs_list = [
            {
                "number": 1,
                "title": "Fix bug",
                "state": "OPEN",
                "isDraft": False,
                "headRefName": "fix-branch",
                "headRefOid": "1234567890",
                "reviewDecision": "APPROVED",
                "mergeable": "MERGEABLE",
                "mergeStateStatus": "CLEAN",
                "statusCheckRollup": [{"conclusion": "SUCCESS", "name": "build"}],
                "additions": 10,
                "deletions": 2,
                "changedFiles": 1,
            }
        ]
        text, bad = prs.render(prs_list, {}, "owner/repo")
        self.assertFalse(bad)
        self.assertIn("# PR state -- owner/repo", text)
        self.assertIn("| #1 | open |", text)
        self.assertIn("| pass |", text)


if __name__ == "__main__":
    unittest.main()
