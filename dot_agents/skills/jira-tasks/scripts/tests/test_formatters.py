import unittest
import sys
import os

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.formatters import _flatten_adf_list

class TestFormatters(unittest.TestCase):
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

if __name__ == "__main__":
    unittest.main()
