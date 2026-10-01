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
name: [invalid yaml
---
# Body
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        with self.assertRaises(ValueError):
            validate.split_skill_md(self.skill_md_path)

    def test_valid_yaml_with_trailing_comment_and_unquoted_tail(self):
        content = """---
metadata: {"a": 1} # note
name: "quoted" (important)
---
# Body
"""
        self.skill_md_path.write_text(content, encoding="utf-8")
        meta, body_lines = validate.split_skill_md(self.skill_md_path)
        self.assertEqual(meta["metadata"], '{"a": 1}')
        self.assertEqual(meta["name"], '"quoted" (important)')

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

if __name__ == "__main__":
    unittest.main()
