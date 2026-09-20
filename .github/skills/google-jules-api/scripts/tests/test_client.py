import json
import os
import sys
import unittest
from datetime import datetime, timezone, timedelta
from pathlib import Path
from unittest.mock import MagicMock, patch

# Add scripts directory to sys.path
scripts_dir = Path(__file__).resolve().parent.parent
if str(scripts_dir) not in sys.path:
    sys.path.insert(0, str(scripts_dir))

from jules.auth import resolve_jules_api_key
from jules.client import JulesClient
from jules.formatters import (
    format_activities,
    format_activity,
    format_session,
    format_sessions,
    format_session_check,
    format_source,
    format_sources,
)


class TestJulesAuth(unittest.TestCase):
    def test_explicit_token(self):
        token = resolve_jules_api_key("explicit_secret_123")
        self.assertEqual(token, "explicit_secret_123")

    def test_env_token(self):
        with patch.dict(os.environ, {"JULES_API_KEY": "env_secret_456"}, clear=True):
            token = resolve_jules_api_key()
            self.assertEqual(token, "env_secret_456")

    def test_missing_token(self):
        with patch.dict(os.environ, {}, clear=True):
            token = resolve_jules_api_key()
            self.assertIsNone(token)


class TestJulesClient(unittest.TestCase):
    def setUp(self):
        self.client = JulesClient(api_key="test_api_key_123")

    @patch("jules.client.urlopen")
    def test_list_sources(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({
            "sources": [
                {
                    "name": "sources/github/warpcode/cloakenv",
                    "id": "github/warpcode/cloakenv",
                    "githubRepo": {
                        "owner": "warpcode",
                        "repo": "cloakenv",
                        "defaultBranch": {"displayName": "main"},
                        "branches": [{"displayName": "main"}],
                    },
                }
            ]
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        data = self.client.list_sources()
        self.assertIn("sources", data)
        self.assertEqual(len(data["sources"]), 1)
        self.assertEqual(data["sources"][0]["id"], "github/warpcode/cloakenv")

    @patch("jules.client.urlopen")
    def test_get_session(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({
            "id": "4475409647262242777",
            "title": "Refactor Memory",
            "state": "COMPLETED",
            "sourceContext": {
                "source": "sources/github/warpcode/cloakenv",
                "githubRepoContext": {"startingBranch": "main"},
            },
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        data = self.client.get_session("4475409647262242777")
        self.assertEqual(data["id"], "4475409647262242777")
        self.assertEqual(data["state"], "COMPLETED")

    @patch("jules.client.urlopen")
    def test_create_session(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({
            "id": "9999999999999999999",
            "title": "New Task",
            "state": "QUEUED",
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        data = self.client.create_session(
            prompt="Run linter across repository",
            source="github/warpcode/cloakpkg",
            starting_branch="main",
            title="New Task",
        )
        self.assertEqual(data["id"], "9999999999999999999")
        self.assertEqual(data["state"], "QUEUED")

    @patch("jules.client.urlopen")
    def test_send_message_success(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({
            "name": "sessions/4475409647262242777/activities/act-123",
            "originator": "user",
            "userMessage": {"message": "Please add unit tests."},
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        data = self.client.send_message("4475409647262242777", "Please add unit tests.")

        self.assertEqual(data.get("originator"), "user")
        self.assertTrue(data.get("name", "").endswith("/activities/act-123"))

        mock_urlopen.assert_called_once()
        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.get_full_url(), "https://jules.googleapis.com/v1alpha/sessions/4475409647262242777:sendMessage")
        self.assertEqual(req.get_method(), "POST")
        self.assertEqual(json.loads(req.data.decode("utf-8")), {"prompt": "Please add unit tests."})

    @patch("jules.client.urlopen")
    def test_send_message_with_session_prefix_and_whitespace(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({}).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        self.client.send_message("  sessions/4475409647262242777  ", "  Trimmed message  ")

        mock_urlopen.assert_called_once()
        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.get_full_url(), "https://jules.googleapis.com/v1alpha/sessions/4475409647262242777:sendMessage")
        self.assertEqual(req.get_method(), "POST")
        self.assertEqual(json.loads(req.data.decode("utf-8")), {"prompt": "Trimmed message"})

    @patch("jules.client.urlopen")
    def test_approve_plan(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({}).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        res = self.client.approve_plan("4475409647262242777", "plan-123")
        self.assertEqual(res, {})

        mock_urlopen.assert_called_once()
        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.get_full_url(), "https://jules.googleapis.com/v1alpha/sessions/4475409647262242777:approvePlan")
        self.assertEqual(req.get_method(), "POST")
        self.assertEqual(json.loads(req.data.decode("utf-8")), {})

    @patch("jules.client.urlopen")
    def test_get_all_activities(self, mock_urlopen):
        resp1 = MagicMock()
        resp1.getcode.return_value = 200
        resp1.read.return_value = json.dumps({
            "activities": [{"id": "act-1", "createTime": "2026-08-22T08:00:00Z"}],
            "nextPageToken": "tok2",
        }).encode("utf-8")

        resp2 = MagicMock()
        resp2.getcode.return_value = 200
        resp2.read.return_value = json.dumps({
            "activities": [{"id": "act-2", "createTime": "2026-08-22T08:05:00Z"}],
        }).encode("utf-8")

        mock_urlopen.return_value.__enter__.side_effect = [resp1, resp2]

        acts = self.client.get_all_activities("4475409647262242777")
        self.assertEqual(len(acts), 2)
        self.assertEqual(acts[0]["id"], "act-1")
        self.assertEqual(acts[1]["id"], "act-2")

    @patch("jules.client.urlopen")
    def test_audit_session(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({
            "activities": [
                {
                    "id": "act-plan",
                    "originator": "agent",
                    "createTime": "2026-08-22T08:50:25Z",
                    "planGenerated": {
                        "plan": {"id": "plan-123", "steps": [{"title": "Step 1"}]}
                    },
                }
            ]
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        now = datetime.now(timezone.utc)
        sess_data = {
            "id": "4475409647262242777",
            "title": "Fix bug",
            "state": "AWAITING_PLAN_APPROVAL",
            "createTime": (now - timedelta(days=1)).isoformat(),
            "updateTime": (now - timedelta(hours=2)).isoformat(),
            "outputs": [],
        }

        audit = self.client.audit_session(sess_data, stale_threshold_mins=60)
        self.assertEqual(audit["id"], "4475409647262242777")
        self.assertEqual(audit["assessment"], "AWAITING_PLAN_APPROVAL")
        self.assertEqual(audit["pending_plan_id"], "plan-123")
        self.assertFalse(audit["is_inactive"])

    @patch("jules.client.urlopen")
    def test_audit_session_inactive_over_30_days(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({"activities": []}).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        now = datetime.now(timezone.utc)
        sess_data = {
            "id": "1111111111111111111",
            "title": "Old Task",
            "state": "IN_PROGRESS",
            "createTime": (now - timedelta(days=45)).isoformat(),
            "updateTime": (now - timedelta(days=40)).isoformat(),
            "outputs": [],
        }

        audit = self.client.audit_session(sess_data, max_age_days=30)
        self.assertEqual(audit["id"], "1111111111111111111")
        self.assertEqual(audit["assessment"], "INACTIVE")
        self.assertTrue(audit["is_inactive"])
        self.assertGreater(audit["age_days"], 30)

    @patch.object(JulesClient, "list_sessions")
    @patch.object(JulesClient, "audit_session")
    def test_audit_sessions_filters_max_age_days(self, mock_audit, mock_list):
        now = datetime.now(timezone.utc)
        recent_sess = {
            "id": "recent-1",
            "createTime": (now - timedelta(days=2)).isoformat(),
            "updateTime": (now - timedelta(hours=1)).isoformat(),
        }
        old_sess = {
            "id": "old-2",
            "createTime": (now - timedelta(days=35)).isoformat(),
            "updateTime": (now - timedelta(days=32)).isoformat(),
        }

        mock_list.return_value = {"sessions": [recent_sess, old_sess]}
        mock_audit.return_value = {"id": "recent-1", "assessment": "ACTIVE"}

        audits = self.client.audit_sessions(page_size=10, max_age_days=30)

        self.assertEqual(len(audits), 1)
        self.assertEqual(audits[0]["id"], "recent-1")
        mock_audit.assert_called_once_with(recent_sess, stale_threshold_mins=60, max_age_days=30)


class TestJulesFormatters(unittest.TestCase):
    def test_format_sources(self):
        data = {
            "sources": [
                {
                    "id": "github/warpcode/cloakenv",
                    "githubRepo": {
                        "defaultBranch": {"displayName": "main"},
                        "branches": [{"displayName": "main"}],
                    },
                }
            ],
            "nextPageToken": "token123",
        }
        md = format_sources(data)
        self.assertIn("github/warpcode/cloakenv", md)
        self.assertIn("main", md)
        self.assertIn("token123", md)

    def test_format_sources_empty(self):
        self.assertEqual(format_sources({}), "_No connected repositories found._")
        self.assertEqual(format_sources({"sources": []}), "_No connected repositories found._")

    def test_format_sources_name_fallback(self):
        data = {
            "sources": [
                {
                    "name": "sources/github/owner/repo"
                }
            ]
        }
        md = format_sources(data)
        self.assertIn("github/owner/repo", md)
        self.assertIn("N/A", md)

    def test_format_sources_missing_repo_info(self):
        data = {
            "sources": [
                {
                    "id": "repo1"
                }
            ]
        }
        md = format_sources(data)
        self.assertIn("repo1", md)
        self.assertIn("N/A", md)

    def test_format_sessions(self):
        data = {
            "sessions": [
                {
                    "id": "4475409647262242777",
                    "state": "COMPLETED",
                    "title": "Refactor Memory Scrubbing",
                    "sourceContext": {
                        "source": "sources/github/warpcode/cloakenv",
                        "githubRepoContext": {"startingBranch": "main"},
                    },
                    "outputs": [
                        {
                            "pullRequest": {
                                "url": "https://github.com/warpcode/cloakenv/pull/116",
                            }
                        }
                    ],
                }
            ]
        }
        md = format_sessions(data)
        self.assertIn("4475409647262242777", md)
        self.assertIn("COMPLETED", md)
        self.assertIn("PR #116", md)

    def test_format_session(self):
        data = {
            "id": "4475409647262242777",
            "title": "Refactor Memory Scrubbing",
            "state": "COMPLETED",
            "prompt": "Scrub sensitive memory buffers.",
            "sourceContext": {
                "source": "sources/github/warpcode/cloakenv",
                "githubRepoContext": {"startingBranch": "main"},
            },
            "outputs": [
                {
                    "pullRequest": {
                        "url": "https://github.com/warpcode/cloakenv/pull/116",
                        "title": "refactor: zero sensitive byte slices",
                        "baseRef": "main",
                        "headRef": "patch-116",
                    }
                }
            ],
        }
        md = format_session(data)
        self.assertIn("4475409647262242777", md)
        self.assertIn("Scrub sensitive memory buffers", md)
        self.assertIn("patch-116", md)

    def test_format_activities(self):
        data = {
            "activities": [
                {
                    "id": "act-12345678",
                    "originator": "agent",
                    "createTime": "2026-08-22T08:50:25Z",
                    "planGenerated": {
                        "plan": {
                            "id": "plan-999",
                            "steps": [{"title": "Step 1"}],
                        }
                    },
                }
            ]
        }
        md = format_activities(data)
        self.assertIn("act-1234", md)
        self.assertIn("Plan Generated", md)

    def test_format_session_check(self):
        audits = [
            {
                "id": "111",
                "title": "Task 1",
                "state": "AWAITING_PLAN_APPROVAL",
                "assessment": "AWAITING_PLAN_APPROVAL",
                "inactive_mins": 5.0,
                "latest_detail": "Plan generated",
                "pull_request_url": "",
                "pending_plan_id": "plan-xyz",
            },
            {
                "id": "222",
                "title": "Task 2",
                "state": "IN_PROGRESS",
                "assessment": "STALLED",
                "inactive_mins": 75.0,
                "latest_type": "agentMessaged",
                "latest_detail": "Working on tests",
                "pull_request_url": "",
                "pending_plan_id": "",
            },
        ]
        md = format_session_check(audits)
        self.assertIn("111", md)
        self.assertIn("PLAN_GATE", md)
        self.assertIn("plan-xyz", md)
        self.assertIn("222", md)
        self.assertIn("STALLED", md)

    def test_format_session_check_inactive(self):
        audits = [
            {
                "id": "333",
                "title": "Ancient Task",
                "state": "IN_PROGRESS",
                "assessment": "INACTIVE",
                "is_inactive": True,
                "age_days": 42.5,
                "inactive_mins": 61200.0,
                "latest_type": "none",
                "latest_detail": "",
                "pull_request_url": "",
                "pending_plan_id": "",
            }
        ]
        md = format_session_check(audits)
        self.assertIn("333", md)
        self.assertIn("INACTIVE", md)
        self.assertIn("42.5d", md)
        # Verify inactive sessions are not in stalled/actionable lists
        self.assertNotIn("#### Stalled / Silent Sessions", md)
        self.assertNotIn("### Actionable Items", md)


if __name__ == "__main__":
    unittest.main()

