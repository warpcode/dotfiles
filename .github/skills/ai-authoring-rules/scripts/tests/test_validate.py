import os
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, SCRIPT_DIR)

import validate


class TestValidateRule(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.tmp = Path(self.temp_dir.name)

    def test_nonexistent_file(self):
        res = validate.validate_rule(self.tmp / "nonexistent.md")
        self.assertEqual(res, [("file-exists", "FAIL", f"File not found: {(self.tmp / 'nonexistent.md').resolve()}")])

    def test_root_memory_file(self):
        agents_md = self.tmp / "AGENTS.md"
        agents_md.write_text("# Agents Guidelines\nSome instructions here.")
        res = validate.validate_rule(agents_md)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("body-content"), "PASS")

    def test_filename_format(self):
        bad_name = self.tmp / "Bad_Name.md"
        bad_name.write_text("---\n---\n# Valid Body Text Here")
        res = validate.validate_rule(bad_name)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("filename-format"), "FAIL")

        good_name = self.tmp / "good-name.md"
        good_name.write_text("---\n---\n# Valid Body Text Here")
        res = validate.validate_rule(good_name)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("filename-format"), "PASS")

    def test_cursor_rules(self):
        cursor_file = self.tmp / "test-rule.mdc"
        cursor_file.write_text(
            "---\n"
            "alwaysApply: invalid_bool\n"
            "globs: true\n"
            "---\n"
            "# Valid Body Text Here"
        )
        res = validate.validate_rule(cursor_file)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("cursor-extension"), "PASS")
        self.assertEqual(statuses.get("cursor-always-apply"), "FAIL")
        self.assertEqual(statuses.get("cursor-globs"), "FAIL")

    def test_copilot_rules(self):
        copilot_file = self.tmp / "test-rule.instructions.md"
        copilot_file.write_text(
            "---\n"
            "applyTo: true\n"
            "excludeAgent: unknown-agent\n"
            "---\n"
            "# Valid Body Text Here"
        )
        res = validate.validate_rule(copilot_file)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("copilot-extension"), "PASS")
        self.assertEqual(statuses.get("copilot-apply-to"), "FAIL")
        self.assertEqual(statuses.get("copilot-exclude-agent"), "WARN")

    def test_antigravity_rules(self):
        antigravity_file = self.tmp / "antigravity.md"
        antigravity_file.write_text(
            "---\n"
            "trigger: glob\n"
            "---\n"
            "# Valid Body Text Here"
        )
        res = validate.validate_rule(antigravity_file)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("antigravity-trigger"), "PASS")
        self.assertEqual(statuses.get("antigravity-glob-pattern"), "FAIL")

    def test_claude_rules(self):
        claude_file = self.tmp / "claude.md"
        claude_file.write_text(
            "---\n"
            "paths: true\n"
            "---\n"
            "# Valid Body Text Here"
        )
        res = validate.validate_rule(claude_file)
        statuses = {c: s for c, s, _ in res}
        self.assertEqual(statuses.get("claude-paths"), "FAIL")


if __name__ == "__main__":
    unittest.main()
