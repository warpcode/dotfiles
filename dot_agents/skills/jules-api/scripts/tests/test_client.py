import json
import os
import sys
import unittest
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
    def test_get_source(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({
            "name": "sources/github/warpcode/cloakenv",
            "id": "github/warpcode/cloakenv",
            "githubRepo": {
                "owner": "warpcode",
                "repo": "cloakenv",
                "defaultBranch": {"displayName": "main"},
            },
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_response

        # Test without sources/ prefix
        data = self.client.get_source("github/warpcode/cloakenv")
        self.assertEqual(data["name"], "sources/github/warpcode/cloakenv")
        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.full_url, "https://jules.googleapis.com/v1alpha/sources/github/warpcode/cloakenv")

        # Test with sources/ prefix and whitespace
        data_with_prefix = self.client.get_source("  sources/github/warpcode/cloakenv  ")
        self.assertEqual(data_with_prefix["name"], "sources/github/warpcode/cloakenv")
        req_with_prefix = mock_urlopen.call_args[0][0]
        self.assertEqual(req_with_prefix.full_url, "https://jules.googleapis.com/v1alpha/sources/github/warpcode/cloakenv")

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


if __name__ == "__main__":
    unittest.main()

