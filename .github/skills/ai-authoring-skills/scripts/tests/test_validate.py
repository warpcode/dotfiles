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


if __name__ == "__main__":
    unittest.main()
