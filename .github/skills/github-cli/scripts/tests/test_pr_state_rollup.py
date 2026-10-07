import unittest
import sys
from pathlib import Path

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
