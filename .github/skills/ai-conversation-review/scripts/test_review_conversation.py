#!/usr/bin/env python3
"""test_review_conversation.py - Comprehensive unit tests for unified review script."""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))
from review_conversation import (
    classify_script_candidate,
    compare_history,
    ingest_session,
    normalize_tool_key,
    record_history_entry,
    resolve_target,
    run_offload_analysis,
    run_schema_analysis,
    run_segment_analysis,
    run_size_analysis,
    shell_pipe_count,
    USER_CORRECTION_PATTERN,
)


class TestReviewConversation(unittest.TestCase):
    def test_normalize_tool_key(self):
        self.assertEqual(normalize_tool_key("read_file", {}), "read_file")
        self.assertEqual(normalize_tool_key("run_in_terminal", {"command": "git show HEAD"}), "sh:git show")
        self.assertEqual(normalize_tool_key("bash", {"command": "python3 script.py"}), "sh:script.py")
        self.assertEqual(normalize_tool_key("bash", {"command": "curl -s https://example.com"}), "sh:curl")
        self.assertEqual(normalize_tool_key("terminal", {"command": "docker run -it alpine"}), "sh:docker run")

    def test_shell_pipe_count(self):
        self.assertEqual(shell_pipe_count("ls -la | grep foo | sort | uniq"), 3)
        self.assertEqual(shell_pipe_count("git log --oneline | head -n 10"), 1)
        self.assertEqual(shell_pipe_count('grep "a|b" file.txt | wc -l'), 1)
        self.assertEqual(shell_pipe_count("cmd1 || cmd2 | cmd3"), 1)

    def test_user_correction_pattern(self):
        self.assertTrue(USER_CORRECTION_PATTERN.search("Wait, you did check master right?"))
        self.assertTrue(USER_CORRECTION_PATTERN.search("please ensure you provide line numbers"))
        self.assertTrue(USER_CORRECTION_PATTERN.search("That is wrong, use instead the staging branch"))
        self.assertTrue(USER_CORRECTION_PATTERN.search("Follow the template"))
        self.assertFalse(USER_CORRECTION_PATTERN.search("Hello world, let us proceed"))

    def test_classify_script_candidate(self):
        sclass, sname = classify_script_candidate(("sh:git show", "sh:git grep"), ["git show HEAD", "git grep foo"])
        self.assertEqual(sclass, "Script")
        self.assertIn("git-show_git-grep", sname)

        sclass2, sname2 = classify_script_candidate(("grep_search", "read_file"), ["query:foo", "bar.php"])
        self.assertEqual(sclass2, "Script + flags")
        self.assertIn("grep_read", sname2)

    def test_copilot_jsonl_parsing_and_modes(self):
        records = [
            {"type": "session.start", "timestamp": "2026-10-06T10:00:00Z", "data": {"sessionId": "sess-123", "producer": "copilot-agent"}},
            {"type": "user.message", "timestamp": "2026-10-06T10:00:01Z", "data": {"content": "Check PR #123"}},
            {"type": "assistant.message", "timestamp": "2026-10-06T10:00:02Z", "data": {"content": "Checking PR..."}},
            {"type": "tool.execution_start", "timestamp": "2026-10-06T10:00:03Z", "data": {"toolCallId": "c1", "toolName": "read_file", "arguments": {"filePath": "/a/b.txt"}}},
            {"type": "tool.execution_complete", "timestamp": "2026-10-06T10:00:04Z", "data": {"toolCallId": "c1", "success": True}},
            {"type": "tool.execution_start", "timestamp": "2026-10-06T10:00:05Z", "data": {"toolCallId": "c2", "toolName": "run_in_terminal", "arguments": {"command": "cat foo | grep bar | awk '{print}' | sort"}}},
            {"type": "tool.execution_complete", "timestamp": "2026-10-06T10:00:06Z", "data": {"toolCallId": "c2", "success": False, "error": "Exit 1"}},
            {"type": "user.message", "timestamp": "2026-10-06T10:00:07Z", "data": {"content": "Wait, did you check b.txt?"}},
        ]
        with tempfile.NamedTemporaryFile("w+", suffix=".jsonl", delete=False) as tf:
            for r in records:
                tf.write(json.dumps(r) + "\n")
            tpath = Path(tf.name)

        try:
            target = resolve_target(str(tpath))
            sess = ingest_session(target)
            self.assertEqual(sess.session_id, tpath.stem)
            self.assertEqual(sess.platform, "copilot")
            self.assertEqual(len(sess.user_turns), 2)
            self.assertEqual(len(sess.tool_calls), 2)
            self.assertEqual(len(sess.failed_calls), 1)
            self.assertEqual(sess.failed_calls[0]["call_id"], "c2")
            self.assertEqual(sess.command_smells["deep_pipelines"], 1)

            # Check user correction detected on turn 2
            self.assertTrue(sess.user_turns[1]["is_correction"])
            self.assertEqual(sess.user_turns[1]["turn_num"], 2)

            # Check Schema mode
            schema_out = run_schema_analysis(sess)
            self.assertIn("Field Identification", schema_out)
            self.assertIn("data.toolName", schema_out)

            # Check Sizes mode
            sizes_out = run_size_analysis(sess)
            self.assertIn("Bytes by Event Type", sizes_out)
            self.assertIn("read_file", sizes_out)

            # Check Segment mode
            seg_out = run_segment_analysis(sess, "final")
            self.assertIn("Segment Slice", seg_out)

            # Run offload analysis
            offload = run_offload_analysis(sess)
            self.assertEqual(offload["tool_calls"], 2)
        finally:
            if tpath.exists():
                tpath.unlink()

    def test_antigravity_format(self):
        records = [
            {"step_index": 0, "source": "SYSTEM", "type": "SYSTEM_MESSAGE", "status": "DONE", "created_at": "2026-10-07T12:00:00Z", "content": "Initial prompt"},
            {"step_index": 1, "source": "MODEL", "type": "PLANNER_RESPONSE", "status": "DONE", "created_at": "2026-10-07T12:00:01Z", "tool_calls": [{"id": "t1", "name": "run_command", "args": {"CommandLine": "ls -la"}}]},
            {"step_index": 2, "source": "MODEL", "type": "GENERIC", "status": "DONE", "created_at": "2026-10-07T12:00:02Z", "content": "total 48\n-rw-r--r-- file.txt"},
            {"step_index": 3, "source": "MODEL", "type": "PLANNER_RESPONSE", "status": "DONE", "created_at": "2026-10-07T12:00:03Z", "tool_calls": [{"id": "t2", "name": "run_command", "args": {"CommandLine": "cat missing"}}]},
            {"step_index": 4, "source": "MODEL", "type": "GENERIC", "status": "DONE", "created_at": "2026-10-07T12:00:04Z", "content": "exited with code 1\nNo such file"},
        ]
        with tempfile.NamedTemporaryFile("w+", suffix=".jsonl", delete=False) as tf:
            for r in records:
                tf.write(json.dumps(r) + "\n")
            tpath = Path(tf.name)

        try:
            target = resolve_target(str(tpath))
            target.platform = "antigravity"
            sess = ingest_session(target)
            self.assertEqual(len(sess.user_turns), 1)
            self.assertEqual(len(sess.tool_calls), 2)
            self.assertTrue(sess.total_result_bytes > 0)
            self.assertEqual(len(sess.failed_calls), 1)
            self.assertEqual(sess.failed_calls[0]["call_id"], "t2")
        finally:
            if tpath.exists():
                tpath.unlink()

    def test_history_recording_and_comparison(self):
        with tempfile.TemporaryDirectory() as td:
            hfile = Path(td) / "review-history.jsonl"
            entry1 = {
                "session_id": "s1",
                "tool_calls": 50,
                "failed_calls": 5,
                "offloadable_share": 0.80,
            }
            record_history_entry(hfile, entry1)

            entry2 = {
                "session_id": "s2",
                "tool_calls": 40,
                "failed_calls": 2,
                "offloadable_share": 0.90,
            }
            cmp = compare_history(entry2, entry1)
            self.assertIn("40 (-10 vs baseline 50)", cmp["calls_comparison"])
            self.assertIn("90% (prev: 80%)", cmp["offload_comparison"])
            self.assertIn("2 (prev: 5)", cmp["fails_comparison"])


if __name__ == "__main__":
    unittest.main()
