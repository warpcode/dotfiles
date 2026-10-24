import unittest
import sys
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add script directory to sys.path
script_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(script_dir))

import pr_state_rollup as prs


class TestPRStateRollup(unittest.TestCase):
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

    @patch("pr_state_rollup.subprocess.run")
    def test_run_success(self, mock_sub_run):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = "hello stdout"
        mock_proc.stderr = ""
        mock_sub_run.return_value = mock_proc

        code, stdout, stderr = prs.run(["echo", "hello"], check=False)
        self.assertEqual(code, 0)
        self.assertEqual(stdout, "hello stdout")
        self.assertEqual(stderr, "")
        mock_sub_run.assert_called_once_with(["echo", "hello"], capture_output=True, text=True)

    @patch("pr_state_rollup.subprocess.run")
    def test_run_check_failure(self, mock_sub_run):
        mock_proc = MagicMock()
        mock_proc.returncode = 1
        mock_proc.stdout = ""
        mock_proc.stderr = "some error"
        mock_sub_run.return_value = mock_proc

        with self.assertRaises(SystemExit) as cm:
            prs.run(["false"], check=True)
        self.assertEqual(cm.exception.code, 1)

    @patch("pr_state_rollup.run")
    def test_fetch_success(self, mock_run):
        mock_json_data = '[{"number": 1, "title": "Test PR"}]'
        mock_run.return_value = (0, mock_json_data, "")

        result = prs.fetch("owner/repo", "open")
        self.assertEqual(result, [{"number": 1, "title": "Test PR"}])
        mock_run.assert_called_once()
        args, _ = mock_run.call_args
        cmd = args[0]
        self.assertEqual(cmd[0], "gh")
        self.assertEqual(cmd[1], "pr")
        self.assertEqual(cmd[2], "list")
        self.assertIn("--repo", cmd)
        self.assertIn("owner/repo", cmd)
        self.assertIn("--state", cmd)
        self.assertIn("open", cmd)

    @patch("pr_state_rollup.run")
    def test_fetch_empty_output(self, mock_run):
        mock_run.return_value = (0, "", "")

        result = prs.fetch("owner/repo", "open")
        self.assertEqual(result, [])

    @patch("pr_state_rollup.run")
    def test_fetch_error(self, mock_run):
        mock_run.return_value = (1, "", "gh pr list failed")

        with self.assertRaises(SystemExit) as cm:
            prs.fetch("owner/repo", "open")
        self.assertEqual(cm.exception.code, 1)

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
