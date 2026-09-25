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

        self.assertEqual(meta.get("name"), "my-skill")
        self.assertEqual(meta.get("description"), "Does something")
        self.assertEqual(body_lines, ["# Body", "This is the body."])

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
