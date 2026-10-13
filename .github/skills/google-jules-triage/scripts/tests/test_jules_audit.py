#!/usr/bin/env python3
"""Unit tests for jules_audit.py in google-jules-triage skill."""

from datetime import datetime, timezone
import json
import os
import subprocess
import sys
import unittest
from unittest.mock import MagicMock, patch

from pathlib import Path
scripts_dir = Path(__file__).resolve().parent.parent
if str(scripts_dir) not in sys.path:
    sys.path.insert(0, str(scripts_dir))

import jules_audit


class TestJulesAudit(unittest.TestCase):
    def test_parse_and_format_dt(self):
        dt_str = "2026-10-11T12:30:00Z"
        dt = jules_audit.parse_dt(dt_str)
        self.assertIsNotNone(dt)
        self.assertEqual(dt.year, 2026)
        formatted = jules_audit.format_dt(dt_str)
        self.assertEqual(formatted, "2026-10-11 12:30")
        self.assertEqual(jules_audit.format_dt(None), "-")

    def test_audit_session_awaiting_agent_after_user_comment(self):
        """User comment posted after agent activity must mark session as AWAITING_AGENT, not healthy."""
        session = {
            "id": "12345",
            "title": "Fix bug in module",
            "state": "IN_PROGRESS",
            "createTime": "2026-10-11T10:00:00Z",
            "updateTime": "2026-10-11T11:00:00Z",
        }
        activities = [
            {
                "id": "act-1",
                "createTime": "2026-10-11T10:05:00Z",
                "planGenerated": {"plan": {"id": "plan-1", "steps": []}},
            },
            {
                "id": "act-2",
                "createTime": "2026-10-11T10:10:00Z",
                "planApproved": {"planId": "plan-1"},
            },
            {
                "id": "act-3",
                "createTime": "2026-10-11T10:30:00Z",
                "agentMessaged": {"agentMessage": "I have completed step 1."},
            },
            {
                "id": "act-4",
                "createTime": "2026-10-11T10:45:00Z",
                "userMessaged": {
                    "userMessage": "now please respond to the requested changes on the pull request"
                },
            },
        ]
        res = jules_audit.audit_session(session, activities)
        self.assertEqual(res["verdict"], "AWAITING_AGENT")
        self.assertTrue(res["user_newer_than_agent"])
        self.assertEqual(
            res["last_user_message"],
            "now please respond to the requested changes on the pull request",
        )

    def test_audit_session_plan_gate(self):
        """Session with unapproved plan must be PLAN_GATE."""
        session = {
            "id": "plan-sess",
            "title": "Add feature",
            "state": "AWAITING_PLAN_APPROVAL",
            "createTime": "2026-10-11T10:00:00Z",
        }
        activities = [
            {
                "id": "act-1",
                "createTime": "2026-10-11T10:05:00Z",
                "planGenerated": {"plan": {"id": "plan-abc", "steps": [{"title": "Step 1"}]}},
            }
        ]
        res = jules_audit.audit_session(session, activities)
        self.assertEqual(res["verdict"], "PLAN_GATE")

    def test_audit_session_feedback_gate(self):
        """Session where agent asked a question awaiting user response must be FEEDBACK_GATE."""
        session = {
            "id": "feedback-sess",
            "title": "Refactor database query",
            "state": "IN_PROGRESS",
            "createTime": "2026-10-11T10:00:00Z",
        }
        activities = [
            {
                "id": "act-1",
                "createTime": "2026-10-11T10:15:00Z",
                "agentMessaged": {
                    "agentMessage": "Should we proceed with migration or rollback? Please confirm."
                },
            }
        ]
        res = jules_audit.audit_session(session, activities)
        self.assertEqual(res["verdict"], "FEEDBACK_GATE")

    def test_audit_session_junk_detection(self):
        """Degenerate session with garbled / CJK output must be classified as JUNK."""
        session = {
            "id": "junk-sess",
            "title": "Random prompt",
            "state": "IN_PROGRESS",
            "createTime": "2026-10-11T10:00:00Z",
        }
        activities = [
            {
                "id": "act-1",
                "createTime": "2026-10-11T10:01:00Z",
                "agentMessaged": {"agentMessage": "a"},
            },
            {
                "id": "act-2",
                "createTime": "2026-10-11T10:02:00Z",
                "agentMessaged": {"agentMessage": "体 轻 部件"},
            },
            {
                "id": "act-3",
                "createTime": "2026-10-11T10:03:00Z",
                "agentMessaged": {"agentMessage": "Code review rating is #Correct#"},
            },
        ]
        res = jules_audit.audit_session(session, activities)
        self.assertEqual(res["verdict"], "JUNK")

    def test_audit_session_completed_states(self):
        """Completed sessions should be distinguished by PR presence."""
        sess_with_pr = {
            "id": "done-pr",
            "title": "Cleaned up imports",
            "state": "COMPLETED",
            "createTime": "2026-10-11T10:00:00Z",
            "outputs": [{"pullRequest": {"url": "https://github.com/foo/bar/pull/1"}}],
        }
        res_pr = jules_audit.audit_session(sess_with_pr, [])
        self.assertEqual(res_pr["verdict"], "COMPLETED_WITH_PR")

        sess_no_pr = {
            "id": "done-no-pr",
            "title": "Cleaned up imports",
            "state": "COMPLETED",
            "createTime": "2026-10-11T10:00:00Z",
            "outputs": [],
        }
        res_no_pr = jules_audit.audit_session(sess_no_pr, [])
        self.assertEqual(res_no_pr["verdict"], "CLOSED_NO_PR")
        self.assertFalse(res_no_pr["has_git_patch"])

        sess_patch = {
            "id": "done-patch",
            "title": "Cleaned up imports",
            "state": "COMPLETED",
            "createTime": "2026-10-11T10:00:00Z",
            "outputs": [],
        }
        patch_acts = [
            {
                "id": "act-patch",
                "createTime": "2026-10-11T10:30:00Z",
                "artifacts": [
                    {"changeSet": {"gitPatch": {"unidiffPatch": "diff --git a/a b/b\n"}}}
                ],
            }
        ]
        res_patch = jules_audit.audit_session(sess_patch, patch_acts)
        self.assertEqual(res_patch["verdict"], "UNDELIVERED_PATCH")
        self.assertTrue(res_patch["has_git_patch"])

    @patch("jules_audit.inspect_github_pr")
    def test_audit_session_empty_commit_loop(self, mock_inspect):
        """Session with >= 2 empty commits on PR branch must be flagged as EMPTY_COMMIT_LOOP."""
        mock_inspect.return_value = {"empty_commits_count": 2, "mergeable": "MERGEABLE"}
        session = {
            "id": "loop-sess",
            "title": "Fix concurrency bug",
            "state": "IN_PROGRESS",
            "createTime": "2026-10-11T10:00:00Z",
            "outputs": [{"pullRequest": {"url": "https://github.com/foo/bar/pull/99"}}],
        }
        res = jules_audit.audit_session(session, [], check_pr=True)
        self.assertEqual(res["verdict"], "EMPTY_COMMIT_LOOP")

    @patch("jules_audit.inspect_github_pr")
    def test_audit_session_stale_branch(self, mock_inspect):
        """Session with PR merge conflicts must be flagged as STALE_BRANCH."""
        mock_inspect.return_value = {"empty_commits_count": 0, "mergeable": "CONFLICTING"}
        session = {
            "id": "conflict-sess",
            "title": "Resolve merge issue",
            "state": "IN_PROGRESS",
            "createTime": "2026-10-11T10:00:00Z",
            "outputs": [{"pullRequest": {"url": "https://github.com/foo/bar/pull/50"}}],
        }
        res = jules_audit.audit_session(session, [], check_pr=True)
        self.assertEqual(res["verdict"], "STALE_BRANCH")

    def test_format_table(self):
        audits = [
            {
                "id": "6606535531615248010",
                "title": "Sanitize registry keys",
                "state": "IN_PROGRESS",
                "last_activity": "2026-10-11 15:30 (Agent Message)",
                "last_user_message": "now please respond to review",
                "verdict": "AWAITING_AGENT",
            }
        ]
        table = jules_audit.format_table(audits)
        self.assertIn("| id | title | state | last-activity | last-user-msg | verdict |", table)
        self.assertIn("6606535531615248010", table)
        self.assertIn("Sanitize registry keys", table)
        self.assertIn("AWAITING_AGENT", table)

    def test_cli_requires_api_key(self):
        """CLI must exit non-zero when JULES_API_KEY is unset."""
        env = dict(os.environ)
        env.pop("JULES_API_KEY", None)
        proc = subprocess.run(
            [sys.executable, str(scripts_dir / "jules_audit.py"), "--all"],
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("JULES_API_KEY environment variable is required", proc.stderr)

    def test_cli_requires_all_or_session(self):
        """CLI must exit non-zero when neither --all-pages nor --session is provided."""
        env = dict(os.environ)
        env["JULES_API_KEY"] = "fake-key"
        proc = subprocess.run(
            [sys.executable, str(scripts_dir / "jules_audit.py")],
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("Must specify --all-pages or at least one --session ID", proc.stderr)

    @patch("jules_audit.get_client")
    def test_pagination_stops_when_session_exceeds_max_age(self, mock_get_client):
        """Pagination must stop requesting pages once sessions exceed max_age_days."""
        mock_client = MagicMock()
        mock_get_client.return_value = mock_client

        # Page 1 has one recent session and one old session (>30 days old)
        mock_client.list_sessions.return_value = {
            "sessions": [
                {
                    "id": "recent-1",
                    "title": "Recent task",
                    "state": "COMPLETED",
                    "createTime": "2026-10-10T12:00:00Z",
                },
                {
                    "id": "old-1",
                    "title": "Old task",
                    "state": "COMPLETED",
                    "createTime": "2026-08-01T12:00:00Z",
                },
            ],
            "nextPageToken": "page-2-token",
        }
        mock_client.get_all_activities.return_value = []

        with patch.dict(os.environ, {"JULES_API_KEY": "test-key"}), \
             patch("sys.argv", ["jules_audit.py", "--all", "--max-age-days", "30"]):
            jules_audit.main()

        # Only page 1 should have been fetched; page 2 must NOT be requested
        self.assertEqual(mock_client.list_sessions.call_count, 1)

    @patch("jules_audit.get_client")
    def test_days_alias_and_timeout(self, mock_get_client):
        """--days alias sets max_age_days and --timeout passes timeout to get_client."""
        mock_client = MagicMock()
        mock_get_client.return_value = mock_client
        mock_client.list_sessions.return_value = {"sessions": []}

        with patch.dict(os.environ, {"JULES_API_KEY": "test-key"}), \
             patch("sys.argv", ["jules_audit.py", "--all", "--days", "15", "--timeout", "45"]), \
             patch("sys.stderr"):
            jules_audit.main()

        mock_get_client.assert_called_once_with("test-key", timeout=45)

    @patch("jules_audit.get_client")
    def test_archived_sessions_handling(self, mock_get_client):
        """Archived sessions are skipped by default, but included when --include-archived is set."""
        mock_client = MagicMock()
        mock_get_client.return_value = mock_client
        mock_client.list_sessions.return_value = {
            "sessions": [
                {"id": "arch-1", "title": "Archived", "archived": True, "state": "COMPLETED"},
                {"id": "live-1", "title": "Live", "archived": False, "state": "COMPLETED"},
            ]
        }
        mock_client.get_all_activities.return_value = []

        # Default: skip archived
        with patch.dict(os.environ, {"JULES_API_KEY": "test-key"}), \
             patch("sys.argv", ["jules_audit.py", "--all", "--days", "0"]), \
             patch("sys.stderr"):
            jules_audit.main()

        # Only live-1 should have activities requested
        self.assertEqual(mock_client.get_all_activities.call_count, 1)
        mock_client.get_all_activities.assert_called_with("live-1")

        mock_client.get_all_activities.reset_mock()

        # With --include-archived
        with patch.dict(os.environ, {"JULES_API_KEY": "test-key"}), \
             patch("sys.argv", ["jules_audit.py", "--all", "--days", "0", "--include-archived"]), \
             patch("sys.stderr"):
            jules_audit.main()

        # Both arch-1 and live-1 should be processed
        self.assertEqual(mock_client.get_all_activities.call_count, 2)


if __name__ == "__main__":
    unittest.main()

