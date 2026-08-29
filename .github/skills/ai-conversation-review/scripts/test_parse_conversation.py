#!/usr/bin/env python3
import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from parse_conversation import parse_markdown_plain_text, ingest_transcript, generate_markdown_summary

class TestParseConversation(unittest.TestCase):
    def test_parse_markdown_plain_text_roles(self):
        text = """
# User
Hello

## Assistant
Hi there

### Human
How are you?

*AI*:
Doing great!

System:
System message
"""
        events = parse_markdown_plain_text(text)
        self.assertEqual(len(events), 5)
        self.assertEqual(events[0]["role"], "user")
        self.assertEqual(events[0]["content"], "Hello")
        self.assertEqual(events[1]["role"], "assistant")
        self.assertEqual(events[1]["content"], "Hi there")
        self.assertEqual(events[2]["role"], "user")
        self.assertEqual(events[2]["content"], "How are you?")
        self.assertEqual(events[3]["role"], "assistant")
        self.assertEqual(events[3]["content"], "Doing great!")
        self.assertEqual(events[4]["role"], "system")
        self.assertEqual(events[4]["content"], "System message")

    def test_ingest_transcript_markdown(self):
        text = "# User\nTest prompt"
        events = ingest_transcript(text)
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["role"], "user")
        self.assertEqual(events[0]["content"], "Test prompt")

if __name__ == "__main__":
    unittest.main()
