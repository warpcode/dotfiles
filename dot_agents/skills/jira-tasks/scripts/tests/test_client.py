import unittest
from unittest.mock import MagicMock
import sys
import os

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.client import get_status_map

class TestGetStatusMap(unittest.TestCase):
    def test_get_status_map_with_project_key_success(self):
        client = MagicMock()
        client.call.return_value = [
            {
                "statuses": [
                    {"name": "To Do", "statusCategory": {"name": "To Do"}},
                    {"name": "In Progress", "statusCategory": {"name": "In Progress"}}
                ]
            }
        ]
        result = get_status_map(client, project_key="PROJ")
        self.assertEqual(result, {"To Do": "To Do", "In Progress": "In Progress"})
        client.call.assert_called_once_with("GET", "rest/api/3/project/PROJ/statuses")

    def test_get_status_map_global_fallback_when_no_project_key(self):
        client = MagicMock()
        client.call.return_value = [
            {"name": "Done", "statusCategory": {"name": "Done"}},
            {"name": "In Progress", "statusCategory": {"name": "In Progress"}}
        ]
        result = get_status_map(client, project_key=None)
        self.assertEqual(result, {"Done": "Done", "In Progress": "In Progress"})
        client.call.assert_called_once_with("GET", "rest/api/3/status")

    def test_get_status_map_project_key_fails_falls_back_to_global(self):
        client = MagicMock()
        client.call.side_effect = [
            Exception("Project not found"),
            [{"name": "Done", "statusCategory": {"name": "Done"}}]
        ]
        result = get_status_map(client, project_key="INVALID")
        self.assertEqual(result, {"Done": "Done"})
        self.assertEqual(client.call.call_count, 2)

    def test_get_status_map_exception_returns_empty_dict(self):
        client = MagicMock()
        client.call.side_effect = Exception("API connection error")
        result = get_status_map(client, project_key=None)
        self.assertEqual(result, {})

    def test_get_status_map_project_and_global_exceptions_returns_empty_dict(self):
        client = MagicMock()
        client.call.side_effect = Exception("API connection error")
        result = get_status_map(client, project_key="PROJ")
        self.assertEqual(result, {})


if __name__ == "__main__":
    unittest.main()
