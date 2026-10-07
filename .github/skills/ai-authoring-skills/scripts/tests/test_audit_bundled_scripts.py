#!/usr/bin/env python3
"""test_audit_bundled_scripts.py - Unit tests for audit_bundled_scripts.py and validate integration."""

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

# Add parent directory to sys.path
SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, SCRIPT_DIR)

from audit_bundled_scripts import (
    audit_skill_scripts,
    check_skill_references,
    get_bundled_scripts,
)
import validate


class TestAuditBundledScripts(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.skill_dir = Path(self.tmp.name) / "test-skill"
        self.skill_dir.mkdir(parents=True)
        self.scripts_dir = self.skill_dir / "scripts"
        self.scripts_dir.mkdir(parents=True)
        self.ref_dir = self.skill_dir / "references"
        self.ref_dir.mkdir(parents=True)

    def test_get_bundled_scripts_filters_tests_and_non_scripts(self):
        (self.scripts_dir / "active_tool.py").write_text("print('hi')")
        (self.scripts_dir / "helper.sh").write_text("#!/usr/bin/env bash\necho 1")
        (self.scripts_dir / "test_active_tool.py").write_text("# test file")
        (self.scripts_dir / ".hidden.sh").write_text("# hidden")
        (self.scripts_dir / "notes.txt").write_text("not a script")

        scripts = get_bundled_scripts(self.skill_dir)
        names = [s.name for s in scripts]
        self.assertIn("active_tool.py", names)
        self.assertIn("helper.sh", names)
        self.assertNotIn("test_active_tool.py", names)
        self.assertNotIn(".hidden.sh", names)
        self.assertNotIn("notes.txt", names)

    def test_check_skill_references(self):
        (self.skill_dir / "SKILL.md").write_text(
            "---\nname: test-skill\ndescription: Test\n---\nRun `scripts/doc_script.py`\n"
        )
        (self.ref_dir / "details.md").write_text("See `ref_script.sh` for details.")

        self.assertTrue(check_skill_references(self.skill_dir, "doc_script.py"))
        self.assertTrue(check_skill_references(self.skill_dir, "ref_script.sh"))
        self.assertFalse(check_skill_references(self.skill_dir, "unreferenced.py"))

    @patch("audit_bundled_scripts.subprocess.run")
    @patch("audit_bundled_scripts.find_search_tools_script")
    def test_audit_skill_scripts_categorization(self, mock_find, mock_run):
        mock_find.return_value = Path("/fake/search_tools.py")

        (self.scripts_dir / "frequent.py").write_text("# frequent")
        (self.scripts_dir / "rare.py").write_text("# rare")
        (self.scripts_dir / "unused_doc.py").write_text("# unused doc")
        (self.scripts_dir / "unused_orphan.py").write_text("# unused orphan")

        (self.skill_dir / "SKILL.md").write_text(
            "---\nname: test-skill\ndescription: Test\n---\n`unused_doc.py`\n`frequent.py`\n"
        )

        mock_search_json = {
            "scanned_sessions": 200,
            "matched_sessions": 15,
            "results": {
                "frequent.py": {"invocations": 12, "sessions": 8},
                "rare.py": {"invocations": 2, "sessions": 2},
                "unused_doc.py": {"invocations": 0, "sessions": 0},
                "unused_orphan.py": {"invocations": 0, "sessions": 0},
            },
        }

        import json

        class MockProc:
            returncode = 0
            stdout = json.dumps(mock_search_json)
            stderr = ""

        mock_run.return_value = MockProc()

        report = audit_skill_scripts(self.skill_dir, sessions=200)

        scripts = report["scripts"]
        self.assertEqual(scripts["frequent.py"]["status"], "ACTIVE")
        self.assertEqual(scripts["rare.py"]["status"], "LOW_USAGE")
        self.assertEqual(scripts["unused_doc.py"]["status"], "NEVER_USED")
        self.assertEqual(scripts["unused_orphan.py"]["status"], "ORPHAN")

    @patch("validate.audit_skill_scripts")
    def test_validate_script_usage_check_warns_on_obsolete(self, mock_audit):
        (self.scripts_dir / "unused.py").write_text("# code")
        mock_audit.return_value = {
            "scanned_sessions": 200,
            "scripts": {
                "unused.py": {
                    "status": "NEVER_USED",
                    "invocations": 0,
                    "sessions": 0,
                }
            },
        }

        check, status, detail = validate._check_bundled_script_usage(self.skill_dir, sessions=200)
        self.assertEqual(check, "bundled-script-usage")
        self.assertEqual(status, "WARN")
        self.assertIn("obsolete script(s)", detail)
        self.assertIn("unused.py (NEVER_USED)", detail)

    @patch("validate.audit_skill_scripts")
    def test_validate_script_usage_check_passes_when_all_active(self, mock_audit):
        (self.scripts_dir / "active.py").write_text("# code")
        mock_audit.return_value = {
            "scanned_sessions": 200,
            "scripts": {
                "active.py": {
                    "status": "ACTIVE",
                    "invocations": 10,
                    "sessions": 5,
                }
            },
        }

        check, status, detail = validate._check_bundled_script_usage(self.skill_dir, sessions=200)
        self.assertEqual(check, "bundled-script-usage")
        self.assertEqual(status, "PASS")
        self.assertIn("all 1 script(s) active", detail)


if __name__ == "__main__":
    unittest.main()

