import unittest
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.client import get_status_map

class DummyClient:
    def __init__(self, responses=None, raise_on=None):
        self.responses = responses or {}
        self.raise_on = raise_on or set()
        self.calls = []

    def call(self, method, endpoint, payload=None, query_params=None):
        self.calls.append((method, endpoint))
        if endpoint in self.raise_on:
            raise Exception("API Error")
        return self.responses.get(endpoint, [])

class TestGetStatusMap(unittest.TestCase):
    def test_project_statuses(self):
        client = DummyClient(responses={
            "rest/api/3/project/PROJ/statuses": [
                {
                    "name": "Task",
                    "statuses": [
                        {"name": "To Do", "statusCategory": {"name": "To Do"}},
                        {"name": "In Progress", "statusCategory": {"name": "In Progress"}}
                    ]
                },
                {
                    "name": "Bug",
                    "statuses": [
                        {"name": "To Do", "statusCategory": {"name": "To Do"}},
                        {"name": "Done", "statusCategory": {"name": "Done"}}
                    ]
                }
            ]
        })

        mapping = get_status_map(client, "PROJ")
        self.assertEqual(mapping, {
            "To Do": "To Do",
            "In Progress": "In Progress",
            "Done": "Done"
        })

    def test_project_statuses_fallback(self):
        client = DummyClient(
            responses={
                "rest/api/3/status": [
                    {"name": "Backlog", "statusCategory": {"name": "To Do"}},
                    {"name": "Closed", "statusCategory": {"name": "Done"}}
                ]
            },
            raise_on={"rest/api/3/project/FAIL/statuses"}
        )

        mapping = get_status_map(client, "FAIL")
        self.assertEqual(mapping, {
            "Backlog": "To Do",
            "Closed": "Done"
        })

    def test_global_statuses(self):
        client = DummyClient(responses={
            "rest/api/3/status": [
                {"name": "Open", "statusCategory": {"name": "To Do"}},
                {"name": "Resolved", "statusCategory": {"name": "Done"}}
            ]
        })

        mapping = get_status_map(client)
        self.assertEqual(mapping, {
            "Open": "To Do",
            "Resolved": "Done"
        })

    def test_missing_or_none_status_category(self):
        client = DummyClient(responses={
            "rest/api/3/project/PROJ/statuses": [
                {
                    "name": "Task",
                    "statuses": [
                        {"name": "Draft"},
                        {"name": "Review", "statusCategory": None}
                    ]
                }
            ]
        })

        mapping = get_status_map(client, "PROJ")
        self.assertEqual(mapping, {
            "Draft": None,
            "Review": None
        })

if __name__ == "__main__":
    unittest.main()
