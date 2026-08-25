import unittest
from unittest.mock import MagicMock
import sys
import os

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.client import get_status_map

class TestJiraClient(unittest.TestCase):
    def test_get_status_map_project_success(self):
        client = MagicMock()
        client.verbose = False
        client.call.return_value = [
            {
                "statuses": [
                    {"name": "Open", "statusCategory": {"name": "To Do"}},
                    {"name": "In Progress", "statusCategory": {"name": "In Progress"}}
                ]
            }
        ]

        result = get_status_map(client, project_key="PROJ")
        self.assertEqual(result, {"Open": "To Do", "In Progress": "In Progress"})
        client.call.assert_called_once_with("GET", "rest/api/3/project/PROJ/statuses")

    def test_get_status_map_project_failure_fallback_success(self):
        client = MagicMock()
        client.verbose = True

        def call_side_effect(method, endpoint):
            if "project/PROJ/statuses" in endpoint:
                raise Exception("Project statuses failed")
            elif "rest/api/3/status" in endpoint:
                return [
                    {"name": "Done", "statusCategory": {"name": "Done"}}
                ]
            raise Exception("Unexpected endpoint")

        client.call.side_effect = call_side_effect

        result = get_status_map(client, project_key="PROJ")
        self.assertEqual(result, {"Done": "Done"})

    def test_get_status_map_global_failure_returns_empty(self):
        client = MagicMock()
        client.verbose = True
        client.call.side_effect = Exception("Global status failed")

        result = get_status_map(client)
        self.assertEqual(result, {})

if __name__ == "__main__":
    unittest.main()
