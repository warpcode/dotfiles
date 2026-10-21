#!/usr/bin/env python3
import unittest
import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from parse_conversation import (
    parse_markdown_plain_text, ingest_transcript, generate_markdown_summary,
    parse_opencode_jsonl, parse_antigravity_gemini_jsonl, parse_claude_code_session,
    parse_vscode_copilot_jsonl, normalise_tool_calls,
)

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

    def test_generate_markdown_summary_counts(self):
        events = [
            {"role": "user", "content": "Hi", "tool_calls": []},
            {"role": "assistant", "content": "Hello", "tool_calls": [{"name": "tool", "args": {}}]},
            {"role": "assistant", "content": "Here is more", "tool_calls": [{"name": "tool2", "args": {}}, {"name": "tool3", "args": {}}]},
        ]
        summary = generate_markdown_summary(events)
        self.assertIn("**Total Events Extracted:** 3", summary)
        self.assertIn("**User Turns:** 1", summary)
        self.assertIn("**Assistant Turns:** 2", summary)
        self.assertIn("**Tool Invocations:** 3", summary)

class TestToolArgumentRecovery(unittest.TestCase):
    """Regression cover for the bug where every OpenCode tool call rendered as `{}`.

    export_opencode_session.py emits the payload under "arguments"; the renderer only read
    "args"; the VS Code path normalised but the OpenCode path did not. The command-efficiency
    audit -- the entire reason this parser exists -- was therefore blind to OpenCode sessions,
    and silently so, because an empty dict still renders as valid output.
    """

    def _render_opencode(self, tool_calls):
        line = json.dumps({"role": "assistant", "content": "", "tool_calls": tool_calls})
        events = parse_opencode_jsonl([line])
        return generate_markdown_summary(events)

    def test_opencode_arguments_dict_is_rendered(self):
        out = self._render_opencode([
            {"name": "bash", "status": "completed",
             "arguments": {"command": "grep -rn TODO ."}}])
        self.assertIn("grep -rn TODO .", out)
        self.assertNotIn("`{}`", out)

    def test_opencode_arguments_json_string_is_decoded(self):
        out = self._render_opencode([
            {"name": "bash", "arguments": json.dumps({"command": "make build"})}])
        self.assertIn("make build", out)

    def test_existing_args_key_is_preserved(self):
        events = parse_opencode_jsonl([json.dumps({
            "role": "assistant", "content": "",
            "tool_calls": [{"name": "read", "args": {"path": "a.txt"}}]})])
        self.assertEqual(events[0]["tool_calls"][0]["args"], {"path": "a.txt"})
        self.assertIn("a.txt", generate_markdown_summary(events))

    def test_renderer_accepts_raw_arguments_from_direct_callers(self):
        # generate_markdown_summary is public; callers may pass un-normalised rows.
        events = [{"role": "assistant", "content": "",
                   "tool_calls": [{"name": "bash", "arguments": {"command": "ls -la"}}]}]
        self.assertIn("ls -la", generate_markdown_summary(events))

    def test_warning_when_no_arguments_recovered(self):
        out = self._render_opencode([{"name": "bash", "status": "completed"}])
        self.assertIn("No tool arguments were recovered", out)
        self.assertIn("NOT reliable", out)

    def test_no_warning_when_some_arguments_recovered(self):
        out = self._render_opencode([
            {"name": "bash", "arguments": {"command": "true"}},
            {"name": "todo_write", "arguments": {}}])
        self.assertNotIn("No tool arguments were recovered", out)

    def test_no_false_warning_for_legitimately_empty_args(self):
        # A call made with no arguments yields {} from the key itself, not a missing key.
        out = self._render_opencode([{"name": "session_list", "arguments": {}}])
        self.assertNotIn("No tool arguments were recovered", out)

    def test_normaliser_drops_legacy_key(self):
        out = normalise_tool_calls([{"name": "bash", "arguments": {"command": "pwd"}}])
        self.assertNotIn("arguments", out[0])
        self.assertEqual(out[0]["args"], {"command": "pwd"})

    def test_non_dict_entries_are_skipped_not_crashed(self):
        self.assertEqual(normalise_tool_calls(["garbage", None]), [])

    def test_vscode_copilot_arguments_recovery(self):
        lines = [
            json.dumps({
                "type": "tool.execution_start",
                "data": {
                    "toolCallId": "c1",
                    "toolName": "read_file",
                    "arguments": {"filePath": "/a/b.txt"}
                }
            }),
            json.dumps({
                "type": "tool.execution_complete",
                "data": {"toolCallId": "c1", "success": True}
            })
        ]
        events = parse_vscode_copilot_jsonl(lines)
        self.assertEqual(events[0]["tool_calls"][0]["args"], {"filePath": "/a/b.txt"})
        self.assertTrue(events[0]["tool_calls"][0]["args_recovered"])
        summary = generate_markdown_summary(events)
        self.assertIn("/a/b.txt", summary)
        self.assertNotIn("No tool arguments were recovered", summary)

    def test_antigravity_gemini_arguments_recovery(self):
        lines = [
            json.dumps({
                "type": "MODEL",
                "tool_calls": [
                    {"ToolName": "execute_bash", "Arguments": {"command": "git status"}}
                ]
            })
        ]
        events = parse_antigravity_gemini_jsonl(lines)
        self.assertEqual(events[0]["tool_calls"][0]["args"], {"command": "git status"})
        self.assertTrue(events[0]["tool_calls"][0]["args_recovered"])
        summary = generate_markdown_summary(events)
        self.assertIn("git status", summary)
        self.assertNotIn("No tool arguments were recovered", summary)

    def test_claude_code_input_key_recovery(self):
        data = [{
            "role": "assistant",
            "tools": [{"name": "Bash", "input": {"command": "pytest"}}]
        }]
        events = parse_claude_code_session(data)
        self.assertEqual(events[0]["tool_calls"][0]["args"], {"command": "pytest"})
        self.assertTrue(events[0]["tool_calls"][0]["args_recovered"])
        summary = generate_markdown_summary(events)
        self.assertIn("pytest", summary)
        self.assertNotIn("No tool arguments were recovered", summary)

    def test_normalise_tool_calls_handles_various_keys(self):
        tc_input = normalise_tool_calls([{"name": "t1", "input": {"x": 1}}])
        self.assertEqual(tc_input[0]["args"], {"x": 1})
        self.assertTrue(tc_input[0]["args_recovered"])
        self.assertNotIn("input", tc_input[0])

        tc_arguments_cap = normalise_tool_calls([{"name": "t2", "Arguments": {"y": 2}}])
        self.assertEqual(tc_arguments_cap[0]["args"], {"y": 2})
        self.assertTrue(tc_arguments_cap[0]["args_recovered"])
        self.assertNotIn("Arguments", tc_arguments_cap[0])

        tc_no_key = normalise_tool_calls([{"name": "t3"}])
        self.assertEqual(tc_no_key[0]["args"], {})
        self.assertFalse(tc_no_key[0]["args_recovered"])

    def test_renderer_handles_raw_input_and_Arguments_keys(self):
        events = [{"role": "assistant", "content": "",
                   "tool_calls": [{"name": "bash", "input": {"command": "whoami"}}]}]
        out = generate_markdown_summary(events)
        self.assertIn("whoami", out)
        self.assertNotIn("No tool arguments were recovered", out)


if __name__ == "__main__":
    unittest.main()
