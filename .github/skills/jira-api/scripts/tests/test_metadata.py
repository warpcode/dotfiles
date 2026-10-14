import unittest
import sys
import os
import io
import json
from unittest.mock import MagicMock, patch

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.commands.metadata import (
    cmd_fields,
    cmd_statuses,
    cmd_types,
    cmd_priorities,
    cmd_resolutions,
    cmd_projects,
)

class DummyArgs:
    def __init__(self, project=None, raw=False, category=None, filter=None):
        self.project = project
        self.raw = raw
        self.category = category
        self.filter = filter

class TestMetadataCommands(unittest.TestCase):
    def setUp(self):
        self.client = MagicMock()

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_statuses_with_project_deduplication(self, mock_stdout):
        mock_response = [
            {
                "id": "1",
                "name": "Bug",
                "statuses": [
                    {"id": "100", "name": "To Do", "statusCategory": {"name": "To Do"}},
                    {"id": "101", "name": "In Progress", "statusCategory": {"name": "In Progress"}},
                ]
            },
            {
                "id": "2",
                "name": "Task",
                "statuses": [
                    {"id": "101", "name": "In Progress", "statusCategory": {"name": "In Progress"}},
                    {"id": "102", "name": "Done", "statusCategory": {"name": "Complete"}},
                ]
            }
        ]
        self.client.call.return_value = mock_response

        args = DummyArgs(project="PROJ", raw=False)
        cmd_statuses(self.client, args)

        self.client.call.assert_called_once_with("GET", "rest/api/3/project/PROJ/statuses")
        output = json.loads(mock_stdout.getvalue().strip())

        expected = {
            "100": {"name": "To Do", "category": "To Do"},
            "101": {"name": "In Progress", "category": "In Progress"},
            "102": {"name": "Done", "category": "Complete"}
        }
        self.assertEqual(output, expected)

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_statuses_project_raw(self, mock_stdout):
        mock_response = [
            {
                "id": "1",
                "statuses": [
                    {"id": "100", "name": "To Do"},
                    {"id": "101", "name": "In Progress"},
                ]
            },
            {
                "id": "2",
                "statuses": [
                    {"id": "100", "name": "To Do"},
                ]
            }
        ]
        self.client.call.return_value = mock_response

        args = DummyArgs(project="PROJ", raw=True)
        cmd_statuses(self.client, args)

        output = json.loads(mock_stdout.getvalue().strip())
        expected = [
            {"id": "100", "name": "To Do"},
            {"id": "101", "name": "In Progress"}
        ]
        self.assertEqual(output, expected)

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_statuses_category_filter(self, mock_stdout):
        mock_response = [
            {"id": "100", "name": "To Do", "statusCategory": {"name": "To Do"}},
            {"id": "101", "name": "In Progress", "statusCategory": {"name": "In Progress"}},
            {"id": "102", "name": "Done", "statusCategory": {"name": "Done"}}
        ]
        self.client.call.return_value = mock_response

        args = DummyArgs(project=None, raw=False, category="In Progress")
        cmd_statuses(self.client, args)

        output = json.loads(mock_stdout.getvalue().strip())
        expected = {
            "101": {"name": "In Progress", "category": "In Progress"}
        }
        self.assertEqual(output, expected)

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_statuses_edge_cases(self, mock_stdout):
        # Issue types with None statuses or missing statusCategory
        mock_response = [
            {"id": "1", "statuses": None},
            {"id": "2"},
            {
                "id": "3",
                "statuses": [
                    {"id": "200", "name": "Open", "statusCategory": None},
                    {"id": "201", "name": "Closed"}
                ]
            }
        ]
        self.client.call.return_value = mock_response

        args = DummyArgs(project="PROJ", raw=False)
        cmd_statuses(self.client, args)

        output = json.loads(mock_stdout.getvalue().strip())
        expected = {
            "200": {"name": "Open", "category": None},
            "201": {"name": "Closed", "category": None}
        }
        self.assertEqual(output, expected)

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_fields(self, mock_stdout):
        mock_response = [
            {"id": "summary", "name": "Summary"},
            {"id": "description", "name": "Description"}
        ]
        self.client.call.return_value = mock_response

        args = DummyArgs(filter="sum")
        cmd_fields(self.client, args)

        output = json.loads(mock_stdout.getvalue().strip())
        self.assertEqual(output, {"summary": "Summary"})

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_types(self, mock_stdout):
        mock_response = [
            {"id": "1", "name": "Bug", "subtask": False}
        ]
        self.client.call.return_value = mock_response

        args = DummyArgs()
        cmd_types(self.client, args)

        output = json.loads(mock_stdout.getvalue().strip())
        self.assertEqual(output, {"1": {"name": "Bug", "subtask": False}})

if __name__ == "__main__":
    unittest.main()
