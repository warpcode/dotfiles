import os
import sys
import subprocess
import unittest
from unittest.mock import patch, MagicMock

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.auth import resolve_secret


class TestAuth(unittest.TestCase):
    @patch.dict(os.environ, {"MY_SECRET": "env_val"}, clear=True)
    def test_resolve_secret_from_env(self):
        self.assertEqual(resolve_secret("MY_SECRET"), "env_val")

    @patch.dict(os.environ, {"JIRA_API_KEY": "key_val"}, clear=True)
    def test_resolve_jira_api_token_fallback_env(self):
        self.assertEqual(resolve_secret("JIRA_API_TOKEN"), "key_val")

    @patch.dict(os.environ, {}, clear=True)
    def test_resolve_secret_missing_resolver_cmd(self):
        self.assertIsNone(resolve_secret("MY_SECRET"))

    @patch.dict(os.environ, {"DF_SECRET_GET_CMD": "df.secrets get"}, clear=True)
    @patch("subprocess.run")
    def test_resolve_secret_via_cmd(self, mock_run):
        mock_run.return_value = MagicMock(stdout="cmd_val\n", returncode=0)
        result = resolve_secret("MY_SECRET")
        self.assertEqual(result, "cmd_val")
        mock_run.assert_called_once_with(
            ["df.secrets", "get", "MY_SECRET"],
            capture_output=True,
            text=True,
            check=True,
        )

    @patch.dict(os.environ, {"DF_SECRET_GET_CMD": "df.secrets get"}, clear=True)
    @patch("subprocess.run")
    def test_resolve_jira_api_token_cmd_fallback(self, mock_run):
        mock_run.side_effect = [
            MagicMock(stdout="", returncode=0),
            MagicMock(stdout="key_cmd_val\n", returncode=0),
        ]
        result = resolve_secret("JIRA_API_TOKEN")
        self.assertEqual(result, "key_cmd_val")
        self.assertEqual(mock_run.call_count, 2)
        mock_run.assert_any_call(
            ["df.secrets", "get", "JIRA_API_TOKEN"],
            capture_output=True,
            text=True,
            check=True,
        )
        mock_run.assert_any_call(
            ["df.secrets", "get", "JIRA_API_KEY"],
            capture_output=True,
            text=True,
            check=True,
        )

    @patch.dict(os.environ, {"DF_SECRET_GET_CMD": "df.secrets get"}, clear=True)
    @patch("subprocess.run")
    def test_resolve_secret_cmd_called_process_error(self, mock_run):
        mock_run.side_effect = subprocess.CalledProcessError(1, ["df.secrets", "get"])
        self.assertIsNone(resolve_secret("MY_SECRET"))

    @patch.dict(os.environ, {"DF_SECRET_GET_CMD": "invalid_command"}, clear=True)
    @patch("subprocess.run")
    def test_resolve_secret_cmd_file_not_found(self, mock_run):
        mock_run.side_effect = FileNotFoundError()
        self.assertIsNone(resolve_secret("MY_SECRET"))

    @patch.dict(os.environ, {"DF_SECRET_GET_CMD": "df.secrets get"}, clear=True)
    @patch("subprocess.run")
    def test_resolve_secret_cmd_empty_output(self, mock_run):
        mock_run.return_value = MagicMock(stdout="   \n", returncode=0)
        self.assertIsNone(resolve_secret("MY_SECRET"))


if __name__ == "__main__":
    unittest.main()
