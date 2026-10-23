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
import io
from unittest.mock import patch

from search_tools import (
    discover_sessions,
    extract_tool_calls_from_jsonl,
    match_tool_call,
    parse_args,
    print_json_output,
    print_markdown_output,
    process_sessions,
    resolve_target_scripts,
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
            "args": {"CommandLine": "python3 .github/skills/github-pr-review/scripts/verify_review_anchors.sh --list"},
        }
        matched, target = match_tool_call(tc, script_targets={"verify_review_anchors.sh", "other_script.py"})
        self.assertTrue(matched)
        self.assertEqual(target, "verify_review_anchors.sh")

        matched, target = match_tool_call(tc, script_targets={"nonexistent_script.sh"})
        self.assertFalse(matched)
        self.assertIsNone(target)

    def test_match_tool_call_by_script_patterns(self):
        tc = {
            "name": "run_command",
            "args": {"CommandLine": "python3 .github/skills/github-pr-review/scripts/verify_review_anchors.sh --list"},
        }
        targets = {"verify_review_anchors.sh", "other_script.py"}
        patterns = {s: re.compile(rf"(?:^|[\s/\"']){re.escape(s)}(?:[\s\"']|$)") for s in targets}

        matched, target = match_tool_call(tc, script_patterns=patterns)
        self.assertTrue(matched)
        self.assertEqual(target, "verify_review_anchors.sh")

        nonexistent_patterns = {"nonexistent.sh": re.compile(r"(?:^|[\s/\"'])nonexistent\.sh(?:[\s\"']|$)")}
        matched, target = match_tool_call(tc, script_patterns=nonexistent_patterns)
        self.assertFalse(matched)
        self.assertIsNone(target)

        # Assert boundary behavior: partial substring collisions must not match
        prefix_collision_tc = {
            "name": "run_command",
            "args": {"CommandLine": "python3 prefix_verify_review_anchors.sh"},
        }
        matched, target = match_tool_call(prefix_collision_tc, script_patterns=patterns)
        self.assertFalse(matched)
        self.assertIsNone(target)

        suffix_collision_tc = {
            "name": "run_command",
            "args": {"CommandLine": "python3 verify_review_anchors.sh_bak"},
        }
        matched, target = match_tool_call(suffix_collision_tc, script_patterns=patterns)
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

    def test_parse_args(self):
        args = parse_args(["--tool", "run_command", "--sessions", "50", "--json"])
        self.assertEqual(args.tool, "run_command")
        self.assertEqual(args.sessions, 50)
        self.assertTrue(args.json)

    def test_resolve_target_scripts_single_script(self):
        args = parse_args(["--script", "my_script.py"])
        scripts, err = resolve_target_scripts(args)
        self.assertIsNone(err)
        self.assertEqual(scripts, {"my_script.py"})

    def test_resolve_target_scripts_multiple_scripts(self):
        args = parse_args(["--scripts", "a.py, b.sh, c.zsh"])
        scripts, err = resolve_target_scripts(args)
        self.assertIsNone(err)
        self.assertEqual(scripts, {"a.py", "b.sh", "c.zsh"})

    def test_resolve_target_scripts_directory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            p1 = Path(tmpdir) / "helper.py"
            p2 = Path(tmpdir) / "runner.sh"
            p3 = Path(tmpdir) / "test_ignore.py"
            p1.write_text("# py")
            p2.write_text("# sh")
            p3.write_text("# test")

            args = parse_args(["--scripts-dir", tmpdir])
            scripts, err = resolve_target_scripts(args)
            self.assertIsNone(err)
            self.assertEqual(scripts, {"helper.py", "runner.sh"})

    def test_resolve_target_scripts_invalid_directory(self):
        args = parse_args(["--scripts-dir", "/nonexistent/path/to/dir"])
        scripts, err = resolve_target_scripts(args)
        self.assertIsNone(scripts)
        self.assertIn("not a directory", err)

    def test_process_sessions(self):
        with tempfile.NamedTemporaryFile("w+", suffix=".jsonl", delete=False) as tf:
            record = {
                "created_at": "2026-10-07T12:00:00Z",
                "tool_calls": [
                    {"name": "run_command", "args": {"CommandLine": "python3 script.py"}}
                ]
            }
            tf.write(json.dumps(record) + "\n")
            path = Path(tf.name)

        try:
            sref = SessionRef("sess1", "antigravity", path, 100.0)
            tool_re = re.compile("run_command")
            stats, matched_sessions, total_invocations = process_sessions([sref], tool_re=tool_re)

            self.assertEqual(total_invocations, 1)
            self.assertIn("sess1", matched_sessions)
            self.assertEqual(stats["run_command"]["invocations"], 1)
        finally:
            path.unlink(missing_ok=True)

    def test_print_json_output(self):
        sref = SessionRef("sess1", "antigravity", "/tmp/log", 100.0)
        stats = {
            "run_command": {
                "invocations": 6,
                "sessions": {"sess1"},
                "first_seen": "2026-01-01T00:00:00Z",
                "last_seen": "2026-01-02T00:00:00Z",
                "errors": 0,
                "samples": ["git status"],
            }
        }
        with patch("sys.stdout", new=io.StringIO()) as fake_out:
            print_json_output([sref], {"sess1"}, 6, stats)
            output = json.loads(fake_out.getvalue())
            self.assertEqual(output["scanned_sessions"], 1)
            self.assertEqual(output["results"]["run_command"]["status"], "ACTIVE")

    def test_print_markdown_output(self):
        args = parse_args(["--tool", "run_command"])
        sref = SessionRef("sess1", "antigravity", "/tmp/log", 100.0)
        stats = {
            "run_command": {
                "invocations": 1,
                "sessions": {"sess1"},
                "first_seen": "2026-01-01T00:00:00Z",
                "last_seen": "2026-01-02T00:00:00Z",
                "errors": 0,
                "samples": ["git status"],
            }
        }
        with patch("sys.stdout", new=io.StringIO()) as fake_out:
            print_markdown_output(args, [sref], {"sess1"}, 1, stats, None)
            text = fake_out.getvalue()
            self.assertIn("# Tool Usage Audit: tool='run_command'", text)
            self.assertIn("| `run_command` | 1 | 1 | ⚠️ LOW USAGE |", text)


if __name__ == "__main__":
    unittest.main()

