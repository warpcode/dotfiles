#!/usr/bin/env python3
"""test_search_tools.py - Unit tests for search_tools.py in ai-conversation-review."""

import json
import os
import re
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))
from search_tools import (
    discover_sessions,
    extract_tool_calls_from_jsonl,
    match_tool_call,
    SessionRef,
)


class TestSearchTools(unittest.TestCase):
    def test_match_tool_call_by_name(self):
        tc = {
            "name": "run_command",
            "args": {"CommandLine": "git status"},
        }
        matched, target = match_tool_call(tc, tool_re=re.compile(r"^run_command$"))
        self.assertTrue(matched)
        self.assertEqual(target, "run_command")

        matched, target = match_tool_call(tc, tool_re=re.compile(r"^view_file$"))
        self.assertFalse(matched)
        self.assertIsNone(target)

    def test_match_tool_call_by_command(self):
        tc = {
            "name": "run_command",
            "args": {"CommandLine": "gh pr view 123 --json title"},
        }
        matched, target = match_tool_call(tc, command_re=re.compile(r"gh pr view"))
        self.assertTrue(matched)
        self.assertIn("gh pr view", target)

        matched, target = match_tool_call(tc, command_re=re.compile(r"git status"))
        self.assertFalse(matched)
        self.assertIsNone(target)

    def test_match_tool_call_by_script(self):
        tc = {
            "name": "run_command",
            "args": {"CommandLine": "python3 .github/skills/review-pull-request/scripts/verify_review_anchors.sh --list"},
        }
        matched, target = match_tool_call(tc, script_targets={"verify_review_anchors.sh", "other_script.py"})
        self.assertTrue(matched)
        self.assertEqual(target, "verify_review_anchors.sh")

        matched, target = match_tool_call(tc, script_targets={"nonexistent_script.sh"})
        self.assertFalse(matched)
        self.assertIsNone(target)

    def test_extract_tool_calls_from_jsonl(self):
        with tempfile.NamedTemporaryFile("w+", suffix=".jsonl", delete=False) as tf:
            # write mock antigravity transcript line
            record = {
                "step_index": 1,
                "type": "PLANNER_RESPONSE",
                "created_at": "2026-10-07T12:00:00Z",
                "tool_calls": [
                    {
                        "name": "run_command",
                        "args": {
                            "CommandLine": "python3 /path/to/my_tool.py --test"
                        }
                    },
                    {
                        "name": "call_mcp_tool",
                        "args": {
                            "ToolName": "issue_read",
                            "Arguments": {"issue_number": 42}
                        }
                    }
                ]
            }
            tf.write(json.dumps(record) + "\n")
            path = Path(tf.name)

        try:
            tcs = extract_tool_calls_from_jsonl(path)
            self.assertEqual(len(tcs), 2)
            self.assertEqual(tcs[0]["name"], "run_command")
            self.assertEqual(tcs[0]["args"]["CommandLine"], "python3 /path/to/my_tool.py --test")
            # MCP inner tool name unpacking
            self.assertEqual(tcs[1]["name"], "mcp:issue_read")
        finally:
            path.unlink(missing_ok=True)

    def test_discover_sessions_limit_and_filter(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            fake_brain = Path(tmpdir) / "brain"
            fake_s1 = fake_brain / "session-1" / ".system_generated" / "logs"
            fake_s2 = fake_brain / "session-2" / ".system_generated" / "logs"
            fake_s1.mkdir(parents=True)
            fake_s2.mkdir(parents=True)
            (fake_s1 / "transcript.jsonl").write_text("{}\n")
            (fake_s2 / "transcript.jsonl").write_text("{}\n")

            # Patch search roots temporarily
            import search_tools
            old_roots = search_tools.ANTIGRAVITY_BRAIN_PATHS
            search_tools.ANTIGRAVITY_BRAIN_PATHS = [fake_brain]
            try:
                sessions = discover_sessions(limit=1, platform_filter="antigravity")
                self.assertEqual(len(sessions), 1)

                all_sessions = discover_sessions(limit=10, platform_filter="antigravity")
                self.assertEqual(len(all_sessions), 2)
                sids = {s.session_id for s in all_sessions}
                self.assertEqual(sids, {"session-1", "session-2"})
            finally:
                search_tools.ANTIGRAVITY_BRAIN_PATHS = old_roots


if __name__ == "__main__":
    unittest.main()

