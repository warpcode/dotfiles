import unittest
import os
import sys
import tempfile
from pathlib import Path

# Add the script directory to sys.path so we can import the script
SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, SCRIPT_DIR)

import validate

class TestSplitSkillMd(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.skill_md_path = Path(self.temp_dir.name) / "SKILL.md"

    def test_valid_split(self):
        content = """---
name: my-skill
description: Does something
---
# Body
This is the body.
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        meta, body_lines = validate.split_skill_md(self.skill_md_path)

        self.assertEqual(meta, {
            "name": "my-skill",
            "description": "Does something",
        })
        self.assertEqual(body_lines, ["# Body", "This is the body."])

    def test_invalid_yaml_frontmatter(self):
        content = """---
invalid yaml line without colon
---
# Body
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        with self.assertRaises(ValueError):
            validate.split_skill_md(self.skill_md_path)

    def test_standard_markdown_without_frontmatter(self):
        content = """# Header
This is a standard markdown document without any frontmatter.
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        with self.assertRaises(ValueError) as context:
            validate.split_skill_md(self.skill_md_path)
        self.assertIn("missing '---' frontmatter opener on line 1", str(context.exception))

    def test_horizontal_rule_in_body(self):
        content = """---
name: my-skill
description: Does something
---
# Section 1
---
# Section 2
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        meta, body_lines = validate.split_skill_md(self.skill_md_path)
        self.assertEqual(meta, {"name": "my-skill", "description": "Does something"})
        self.assertEqual(body_lines, ["# Section 1", "---", "# Section 2"])

    def test_empty_frontmatter(self):
        content = """---
---
# Body
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        meta, body_lines = validate.split_skill_md(self.skill_md_path)
        self.assertEqual(meta, {})
        self.assertEqual(body_lines, ["# Body"])

    def test_missing_frontmatter_opener(self):
        content = """name: my-skill
description: Does something
---
# Body
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        with self.assertRaises(ValueError) as context:
            validate.split_skill_md(self.skill_md_path)
        self.assertIn("missing '---' frontmatter opener on line 1", str(context.exception))

    def test_empty_file(self):
        self.skill_md_path.write_text("", encoding="utf-8")
        with self.assertRaises(ValueError) as context:
            validate.split_skill_md(self.skill_md_path)
        self.assertIn("missing '---' frontmatter opener on line 1", str(context.exception))

    def test_missing_frontmatter_closer(self):
        content = """---
name: my-skill
description: Does something
# Body
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        with self.assertRaises(ValueError) as context:
            validate.split_skill_md(self.skill_md_path)
        self.assertIn("frontmatter not closed with '---'", str(context.exception))


class TestScriptsCompile(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.skill_dir = Path(self.temp_dir.name) / "test-skill"
        self.skill_dir.mkdir()
        (self.skill_dir / "SKILL.md").write_text(
            "---\n"
            "name: test-skill\n"
            "description: >\n"
            "  Test skill. Use when testing script compilation.\n"
            "---\n"
            "# Body\n"
        )
        self.scripts_dir = self.skill_dir / "scripts"
        self.scripts_dir.mkdir()

    def test_invalid_python_syntax(self):
        bad_py = self.scripts_dir / "broken.py"
        bad_py.write_text("def invalid_syntax(\n")

        results = validate.validate_skill(self.skill_dir)
        compile_fails = [detail for check, status, detail in results if check == "scripts-compile" and status == "FAIL"]
        self.assertEqual(len(compile_fails), 1)
        detail = compile_fails[0]
        self.assertIn("scripts/broken.py", detail)
        self.assertNotIn("\n", detail)

    def test_dangling_python_symlink(self):
        dangling_py = self.scripts_dir / "dangling.py"
        try:
            dangling_py.symlink_to(self.scripts_dir / "nonexistent.py")
        except OSError:
            self.skipTest("Symlinks not supported in this environment")

        results = validate.validate_skill(self.skill_dir)
        compile_fails = [detail for check, status, detail in results if check == "scripts-compile" and status == "FAIL"]
        self.assertEqual(len(compile_fails), 1)
        detail = compile_fails[0]
        self.assertIn("scripts/dangling.py", detail)
        self.assertNotIn("\n", detail)


class TestScriptability(unittest.TestCase):
    """The workflow-scriptability WARN: narration-only workflows must be
    detected, and prohibitions/English prose must not be."""

    def findings(self, *lines):
        return validate._scriptability_findings(list(lines))

    def test_clean_skill_has_no_findings(self):
        self.assertEqual(self.findings(
            "Run `scripts/bundle.sh --repo O/R --pr 42` to gather everything.",
            "Then compare the CI conclusions with the review decision.",
        ), [])

    def test_detects_shell_loop(self):
        found = self.findings("for f in $(git diff --name-only); do")
        self.assertTrue(any("shell loop" in f for f in found), found)

    def test_loop_detected_on_the_keyword_line(self):
        # Matching is line-oriented, so a multi-line loop is reported on the
        # line carrying the keyword. The body alone is indistinguishable from an
        # ordinary pipeline, so it is not flagged.
        found = self.findings(
            "for f in $(git diff --name-only); do",
            "  git show origin/main:$f | jq .path",
        )
        self.assertEqual(len([f for f in found if "shell loop" in f]), 1)

    def test_detects_inline_python(self):
        found = self.findings('Run python3 -c "import json; print(json.load(f))"')
        self.assertTrue(any("inline python3 -c" in f for f in found), found)

    def test_detects_chained_pipe_filter(self):
        found = self.findings("git log --oneline | grep fix | jq -r .sha")
        self.assertTrue(any("chained pipe filter" in f for f in found), found)

    def test_detects_command_chain(self):
        found = self.findings(
            "1. Run gh pr view 42 --json title",
            "2. Run gh pr checks 42",
        )
        self.assertTrue(any("documented instruction lines" in f for f in found),
                        found)

    def test_single_command_line_is_not_a_chain(self):
        self.assertEqual(self.findings("1. Run gh pr view 42 --json title"), [])

    def test_prohibition_is_not_flagged(self):
        self.assertEqual(self.findings(
            "Never write an inline python3 -c script.",
            "Do not use a shell loop here.",
        ), [])

    def test_passing_mention_is_not_flagged(self):
        self.assertEqual(self.findings(
            "Flag any use of `python3 -c \"...\"` as an audit finding.",
            "There is no gh in the local clone; Jules has no API access.",
        ), [])

    def test_english_for_is_not_a_loop(self):
        self.assertEqual(self.findings(
            "Collect the data for the report and summarise it.",
            "Iterate for each open pull request.",
        ), [])

    def test_fenced_code_is_ignored(self):
        text = validate.strip_fenced_blocks([
            "Never do this:",
            "```bash",
            "for f in a b; do gh pr view $f; done",
            "```",
            "Use the bundle instead.",
        ])
        self.assertEqual(validate._scriptability_findings(text), [])

    def test_warn_does_not_fail_the_skill(self):
        with tempfile.TemporaryDirectory() as tmp:
            skill = Path(tmp) / "loopy-skill"
            skill.mkdir()
            (skill / "SKILL.md").write_text(
                "---\n"
                "name: loopy-skill\n"
                "description: >\n"
                "  Loops inline. Use when the user asks for a loop.\n"
                "---\n"
                "# Loopy\n"
                "for f in $(git diff --name-only); do\n"
                "  git show origin/main:$f\n"
                "done\n"
            )
            results = validate.validate_skill(skill)
            statuses = {c: s for c, s, _ in results}
            self.assertEqual(statuses["workflow-scriptability"], "WARN")
            self.assertFalse(any(s == "FAIL" for _, s, _ in results))


if __name__ == "__main__":
    unittest.main()
