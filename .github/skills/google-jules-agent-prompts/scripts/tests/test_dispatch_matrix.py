import os
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

# Ensure script directory is in sys.path
SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import dispatch_matrix


class TestDispatchMatrix(unittest.TestCase):

    def test_fetch_connected_sources(self):
        mock_client = MagicMock()
        mock_client.list_sources.side_effect = [
            {
                "sources": [
                    {
                        "name": "sources/org/repo1",
                        "id": "org/repo1",
                        "githubRepo": {
                            "defaultBranch": {"displayName": "main"},
                            "isPrivate": True,
                        },
                    }
                ],
                "nextPageToken": "token1",
            },
            {
                "sources": [
                    {
                        "name": "sources/org/repo2",
                        "id": "org/repo2",
                        "githubRepo": {
                            "defaultBranch": {"displayName": "dev"},
                            "isPrivate": False,
                        },
                    }
                ],
                "nextPageToken": None,
            },
        ]

        sources = dispatch_matrix.fetch_connected_sources(mock_client)
        self.assertEqual(len(sources), 2)
        self.assertIn("org/repo1", sources)
        self.assertEqual(sources["org/repo1"]["default_branch"], "main")
        self.assertTrue(sources["org/repo1"]["is_private"])
        self.assertIn("org/repo2", sources)
        self.assertEqual(sources["org/repo2"]["default_branch"], "dev")

    def test_discover_active_repos(self):
        mock_client = MagicMock()
        mock_client.list_sessions.return_value = {
            "sessions": [
                {
                    "sourceContext": {"source": "sources/org/repo1"},
                    "createTime": "2026-10-10T00:00:00Z",
                }
            ],
            "nextPageToken": None,
        }
        sources_map = {
            "org/repo1": {"id": "org/repo1", "name": "org/repo1", "default_branch": "main"}
        }

        with patch("dispatch_matrix.parse_iso_datetime") as mock_parse:
            from datetime import datetime, timezone
            mock_parse.return_value = datetime.now(timezone.utc)
            active = dispatch_matrix.discover_active_repos(mock_client, sources_map, days_active=30)
            self.assertEqual(active, [("org/repo1", "main")])

    def test_parse_args(self):
        args = dispatch_matrix.parse_args(["--repos", "org/repo1", "--agents", "bolt", "sentinel", "--days-active", "14"])
        self.assertEqual(args.repos, ["org/repo1"])
        self.assertEqual(args.agents, ["bolt", "sentinel"])
        self.assertEqual(args.days_active, 14)
        self.assertTrue(args.require_approval)

    def test_resolve_target_repos_fallback(self):
        sources_map = {
            "org/repo1": {"id": "org/repo1", "name": "org/repo1", "default_branch": "main"}
        }
        mock_client = MagicMock()
        with patch("dispatch_matrix.discover_active_repos", return_value=[]):
            repos = dispatch_matrix.resolve_target_repos(None, mock_client, sources_map, days_active=30)
            self.assertEqual(repos, [("org/repo1", "main")])

    @patch("dispatch_matrix.JULES_CLI")
    @patch("dispatch_matrix.get_jules_client")
    @patch("dispatch_matrix.fetch_connected_sources")
    @patch("dispatch_matrix.subprocess.run")
    def test_main_with_explicit_repos(self, mock_subprocess_run, mock_fetch_sources, mock_get_client, mock_jules_cli):
        mock_jules_cli.exists.return_value = True
        mock_fetch_sources.return_value = {
            "org/repo1": {"id": "org/repo1", "name": "org/repo1", "default_branch": "main"}
        }

        def fake_run(cmd, *args, **kwargs):
            if "build_prompts.py" in str(cmd[1]):
                tmp_dir = Path(cmd[2])
                (tmp_dir / "bolt.txt").write_text("dummy prompt")
                return MagicMock(returncode=0, stdout="", stderr="")
            return MagicMock(returncode=0, stdout="Session created: s123\n", stderr="")

        mock_subprocess_run.side_effect = fake_run

        test_args = ["dispatch_matrix.py", "--repos", "org/repo1", "--agents", "bolt"]
        with patch.object(sys, "argv", test_args):
            dispatch_matrix.main()

        # Check subprocess calls: build_prompts + session creation
        self.assertEqual(mock_subprocess_run.call_count, 2)


if __name__ == "__main__":
    unittest.main()
