import unittest
import sys
import os

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from unittest.mock import patch
from jira.formatters import _flatten_adf_list, flatten_adf, process_issue

class TestFormatters(unittest.TestCase):
    def test_flatten_adf_none(self):
        self.assertEqual(flatten_adf(None), "")

    def test_flatten_adf_non_dict_non_list(self):
        self.assertEqual(flatten_adf("invalid input"), "")
        self.assertEqual(flatten_adf(123), "")

    def test_flatten_adf_empty_dict(self):
        self.assertEqual(flatten_adf({}), "")

    def test_flatten_adf_simple_text(self):
        node = {"type": "text", "text": "Hello World"}
        self.assertEqual(flatten_adf(node), "Hello World")

    def test_flatten_adf_paragraph(self):
        node = {
            "type": "paragraph",
            "content": [{"type": "text", "text": "Paragraph text"}]
        }
        self.assertEqual(flatten_adf(node), "Paragraph text\n")

    def test_flatten_adf_complex_doc(self):
        node = {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "heading",
                    "content": [{"type": "text", "text": "Header"}]
                },
                {
                    "type": "paragraph",
                    "content": [
                        {"type": "text", "text": "Hello "},
                        {"type": "mention", "attrs": {"text": "@Alice"}},
                        {"type": "hardBreak"},
                        {"type": "inlineCard", "attrs": {"url": "https://example.com"}}
                    ]
                }
            ]
        }
        expected = "Header\nHello @Alice\nhttps://example.com\n"
        self.assertEqual(flatten_adf(node), expected)

    def test_flatten_adf_list_none_input(self):
        parts = []
        _flatten_adf_list(None, parts)
        self.assertEqual(parts, [])

    def test_flatten_adf_list_empty_list(self):
        parts = []
        _flatten_adf_list([], parts)
        self.assertEqual(parts, [])

    def test_flatten_adf_list_text_node(self):
        parts = []
        node = {"type": "text", "text": "Hello world"}
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["Hello world"])

    def test_flatten_adf_list_hardBreak_node(self):
        parts = []
        node = {"type": "hardBreak"}
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["\n"])

    def test_flatten_adf_list_inlineCard_node(self):
        parts = []
        node = {"type": "inlineCard", "attrs": {"url": "https://example.com"}}
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["https://example.com"])

    def test_flatten_adf_list_mention_node(self):
        parts = []
        node = {"type": "mention", "attrs": {"text": "@JohnDoe"}}
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["@JohnDoe"])

    def test_flatten_adf_list_paragraph_node(self):
        parts = []
        node = {
            "type": "paragraph",
            "content": [
                {"type": "text", "text": "A simple paragraph"}
            ]
        }
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["A simple paragraph", "\n"])

    def test_flatten_adf_list_nested_structure(self):
        parts = []
        node = {
            "type": "paragraph",
            "content": [
                {"type": "text", "text": "Hello "},
                {"type": "mention", "attrs": {"text": "@JaneDoe"}},
                {"type": "text", "text": ", please review "},
                {"type": "inlineCard", "attrs": {"url": "https://example.com/pr/1"}}
            ]
        }
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["Hello ", "@JaneDoe", ", please review ", "https://example.com/pr/1", "\n"])

    def test_flatten_adf_list_unexpected_dict(self):
        parts = []
        node = {"unexpected_key": "value"}
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, [])

    def test_flatten_adf_list_content_without_type(self):
        parts = []
        node = {
            "content": [
                {"type": "text", "text": "Inner text"}
            ]
        }
        _flatten_adf_list(node, parts)
        self.assertEqual(parts, ["Inner text"])

    def test_flatten_adf_list_non_dict_non_list(self):
        parts = []
        _flatten_adf_list("just a string", parts)
        self.assertEqual(parts, [])

    def test_process_issue_minimal(self):
        issue = {"id": "1", "key": "TEST-1"}
        result = process_issue(issue, requested_expands=[])
        self.assertEqual(result["id"], "1")
        self.assertEqual(result["key"], "TEST-1")
        self.assertEqual(result["assignee"], "Unassigned")
        self.assertEqual(result["comment"]["total"], 0)
        self.assertEqual(result["comment"]["comments"], [])

    def test_process_issue_full(self):
        issue = {
            "id": "2",
            "key": "TEST-2",
            "fields": {
                "issuetype": {"name": "Bug"},
                "summary": "Test bug",
                "description": {"type": "paragraph", "content": [{"type": "text", "text": "A bug description"}]},
                "assignee": {"displayName": "John Doe"},
                "parent": {"key": "PARENT-1"},
                "status": {"name": "In Progress"},
                "priority": {"name": "High"},
                "labels": ["backend", "urgent"],
                "components": [{"name": "API"}],
                "created": "2023-01-01T12:00:00Z",
                "updated": "2023-01-02T12:00:00Z",
                "comment": {
                    "total": 1,
                    "comments": [{
                        "author": {"displayName": "Jane Doe"},
                        "created": "2023-01-01T13:00:00Z",
                        "updated": "2023-01-01T13:00:00Z",
                        "body": {"type": "paragraph", "content": [{"type": "text", "text": "Fix this"}]}
                    }]
                }
            }
        }
        result = process_issue(issue, requested_expands=[])
        self.assertEqual(result["id"], "2")
        self.assertEqual(result["key"], "TEST-2")
        self.assertEqual(result["parent"], "PARENT-1")
        self.assertEqual(result["type"], "Bug")
        self.assertEqual(result["summary"], "Test bug")
        self.assertEqual(result["description"], "A bug description")
        self.assertEqual(result["assignee"], "John Doe")
        self.assertEqual(result["status"], "In Progress")
        self.assertEqual(result["priority"], "High")
        self.assertEqual(result["labels"], ["backend", "urgent"])
        self.assertEqual(result["components"], ["API"])
        self.assertEqual(result["created"], "2023-01-01T12:00:00Z")
        self.assertEqual(result["updated"], "2023-01-02T12:00:00Z")
        self.assertEqual(result["comment"]["total"], 1)
        self.assertEqual(len(result["comment"]["comments"]), 1)
        self.assertEqual(result["comment"]["comments"][0]["author"], "Jane Doe")
        self.assertEqual(result["comment"]["comments"][0]["body"], "Fix this")

    def test_process_issue_changelog(self):
        issue = {
            "id": "3",
            "key": "TEST-3",
            "changelog": {
                "histories": [
                    {
                        "id": "100",
                        "author": {"displayName": "John", "accountId": "acc1"},
                        "created": "2023-01-01",
                        "items": [
                            {
                                "field": "status",
                                "fieldId": "status",
                                "from": "1",
                                "fromString": "Open",
                                "to": "3",
                                "toString": "In Progress"
                            }
                        ]
                    }
                ]
            }
        }
        result = process_issue(issue, requested_expands=["changelog"])
        self.assertIn("changelog", result)
        histories = result["changelog"]["histories"]
        self.assertEqual(len(histories), 1)
        self.assertEqual(histories[0]["id"], "100")
        self.assertEqual(histories[0]["author"], "John")
        self.assertEqual(histories[0]["author_id"], "acc1")
        self.assertEqual(len(histories[0]["items"]), 1)
        self.assertEqual(histories[0]["items"][0]["field"], "status")
        self.assertEqual(histories[0]["items"][0]["fromString"], "Open")

    def test_process_issue_transitions(self):
        issue = {
            "id": "4",
            "key": "TEST-4",
            "transitions": [
                {
                    "id": "11",
                    "name": "To Do",
                    "to": {"id": "1", "name": "To Do"},
                    "hasScreen": False,
                    "isGlobal": True,
                    "isInitial": False,
                    "isAvailable": True,
                    "isConditional": False,
                    "isLooped": False
                }
            ]
        }
        result = process_issue(issue, requested_expands=["transitions"])
        self.assertIn("transitions", result)
        transitions = result["transitions"]
        self.assertEqual(len(transitions), 1)
        self.assertEqual(transitions[0]["transitionId"], "11")
        self.assertEqual(transitions[0]["transitionname"], "To Do")
        self.assertEqual(transitions[0]["statusId"], "1")
        self.assertEqual(transitions[0]["statusName"], "To Do")

    def test_process_issue_other_expand(self):
        issue = {
            "id": "5",
            "key": "TEST-5",
            "custom_expand": {"data": "value"}
        }
        result = process_issue(issue, requested_expands=["custom_expand"])
        self.assertIn("custom_expand", result)
        self.assertEqual(result["custom_expand"], {"data": "value"})

    def test_process_issue_full_issue_flag(self):
        issue = {"id": "6", "key": "TEST-6"}
        result = process_issue(issue, requested_expands=[], full_issue=True)
        self.assertIn("original", result)
        self.assertEqual(result["original"], issue)

    @patch('jira.formatters.calculate_metrics')
    def test_process_issue_with_metrics(self, mock_calculate_metrics):
        mock_calculate_metrics.return_value = {"time_in_status": {"Open": 3600}}
        issue = {"id": "7", "key": "TEST-7"}
        result = process_issue(issue, requested_expands=[], status_map={})
        self.assertIn("metrics", result)
        self.assertEqual(result["metrics"], {"time_in_status": {"Open": 3600}})
        mock_calculate_metrics.assert_called_once_with(issue, {})

if __name__ == "__main__":
    unittest.main()
