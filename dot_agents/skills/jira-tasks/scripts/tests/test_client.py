import unittest
from unittest.mock import MagicMock
import sys
import os

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.client import get_status_map

class TestGetStatusMap(unittest.TestCase):
    def test_get_status_map_with_project_key(self):
        client = MagicMock()
        client.call.return_value = [
            {
                "statuses": [
                    {"name": "To Do", "statusCategory": {"name": "To Do"}},
                    {"name": "In Progress", "statusCategory": {"name": "In Progress"}},
                ]
            },
            {
                "statuses": [
                    {"name": "Done", "statusCategory": {"name": "Done"}},
                ]
            },
        ]

        result = get_status_map(client, project_key="PROJ")

        client.call.assert_called_once_with("GET", "rest/api/3/project/PROJ/statuses")
        self.assertEqual(
            result,
            {
                "To Do": "To Do",
                "In Progress": "In Progress",
                "Done": "Done",
            },
        )

    def test_get_status_map_project_key_fallback(self):
        client = MagicMock()
        def mock_call(method, endpoint):
            if "project/PROJ/statuses" in endpoint:
                raise Exception("Project endpoint failed")
            return [
                {"name": "Global Open", "statusCategory": {"name": "To Do"}},
                {"name": "Global Closed", "statusCategory": {"name": "Done"}},
            ]
        client.call.side_effect = mock_call

        result = get_status_map(client, project_key="PROJ")

        self.assertEqual(client.call.call_count, 2)
        client.call.assert_any_call("GET", "rest/api/3/project/PROJ/statuses")
        client.call.assert_any_call("GET", "rest/api/3/status")
        self.assertEqual(
            result,
            {
                "Global Open": "To Do",
                "Global Closed": "Done",
            },
        )

    def test_get_status_map_no_project_key(self):
        client = MagicMock()
        client.call.return_value = [
            {"name": "Open", "statusCategory": {"name": "To Do"}},
            {"name": "Resolved", "statusCategory": {"name": "Done"}},
        ]

        result = get_status_map(client, project_key=None)

        client.call.assert_called_once_with("GET", "rest/api/3/status")
        self.assertEqual(
            result,
            {
                "Open": "To Do",
                "Resolved": "Done",
            },
        )

    def test_get_status_map_all_calls_fail(self):
        client = MagicMock()
        client.call.side_effect = Exception("API error")

        result = get_status_map(client, project_key="PROJ")

        self.assertEqual(client.call.call_count, 2)
        self.assertEqual(result, {})

if __name__ == "__main__":
    unittest.main()
