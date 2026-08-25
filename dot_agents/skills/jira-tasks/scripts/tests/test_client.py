import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import io
import json
from urllib.error import HTTPError

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.client import JiraClient, get_status_map

class TestJiraClient(unittest.TestCase):
    def setUp(self):
        self.client = JiraClient("https://jira.example.com", "user@example.com", "token123")

    @patch("jira.client.urlopen")
    def test_call_success(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = json.dumps({"key": "VAL"}).encode()
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        result = self.client.call("GET", "rest/api/3/issue/10000", query_params={"expand": "names"})
        self.assertEqual(result, {"key": "VAL"})

    @patch("jira.client.urlopen")
    @patch("sys.stderr", new_callable=io.StringIO)
    def test_call_httperror_status_codes(self, mock_stderr, mock_urlopen):
        status_tests = [
            (401, "Authentication failed (401)."),
            (403, "Forbidden (403)."),
            (404, "Not Found (404)."),
            (400, "Bad Request (400)."),
            (500, "Request failed with HTTP 500."),
        ]

        for code, expected_msg in status_tests:
            err_fp = io.BytesIO(b'{"errorMessages":["Something went wrong"]}')
            mock_httperror = HTTPError("https://jira.example.com", code, "Error", {}, err_fp)
            mock_urlopen.side_effect = mock_httperror

            with self.assertRaises(SystemExit) as cm:
                self.client.call("GET", "rest/api/3/issue/10000")
            self.assertEqual(cm.exception.code, 1)
            self.assertIn(expected_msg, mock_stderr.getvalue())

    @patch("jira.client.urlopen")
    @patch("sys.stderr", new_callable=io.StringIO)
    def test_call_httperror_verbose(self, mock_stderr, mock_urlopen):
        verbose_client = JiraClient("https://jira.example.com", "user@example.com", "token123", verbose=True)
        err_fp = io.BytesIO(b'{"errorMessages":["Detailed error"]}')
        mock_httperror = HTTPError("https://jira.example.com", 500, "Server Error", {}, err_fp)
        mock_urlopen.side_effect = mock_httperror

        with self.assertRaises(SystemExit):
            verbose_client.call("POST", "rest/api/3/issue", payload={"summary": "test"})

        stderr_output = mock_stderr.getvalue()
        self.assertIn("HTTP Status: 500", stderr_output)
        self.assertIn('{"errorMessages":["Detailed error"]}', stderr_output)

    @patch("jira.client.urlopen")
    @patch("sys.stderr", new_callable=io.StringIO)
    def test_call_generic_exception(self, mock_stderr, mock_urlopen):
        mock_urlopen.side_effect = Exception("Connection refused")

        with self.assertRaises(SystemExit) as cm:
            self.client.call("GET", "rest/api/3/issue/10000")
        self.assertEqual(cm.exception.code, 1)
        self.assertIn("Request failed: Connection refused", mock_stderr.getvalue())

    @patch.object(JiraClient, "call")
    def test_get_status_map_with_project_key(self, mock_call):
        mock_call.return_value = [
            {
                "statuses": [
                    {"name": "To Do", "statusCategory": {"name": "To Do"}},
                    {"name": "In Progress", "statusCategory": {"name": "In Progress"}}
                ]
            }
        ]
        status_map = get_status_map(self.client, project_key="PROJ")
        self.assertEqual(status_map, {"To Do": "To Do", "In Progress": "In Progress"})
        mock_call.assert_called_once_with("GET", "rest/api/3/project/PROJ/statuses")

    @patch.object(JiraClient, "call")
    def test_get_status_map_fallback_global(self, mock_call):
        def side_effect(method, endpoint):
            if "project" in endpoint:
                raise Exception("Project statuses not found")
            return [
                {"name": "Done", "statusCategory": {"name": "Done"}}
            ]
        mock_call.side_effect = side_effect

        status_map = get_status_map(self.client, project_key="PROJ")
        self.assertEqual(status_map, {"Done": "Done"})

    @patch.object(JiraClient, "call")
    def test_get_status_map_complete_failure(self, mock_call):
        mock_call.side_effect = Exception("API error")
        status_map = get_status_map(self.client)
        self.assertEqual(status_map, {})

if __name__ == "__main__":
    unittest.main()
