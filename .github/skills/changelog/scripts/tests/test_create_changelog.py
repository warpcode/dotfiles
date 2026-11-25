import importlib.util
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT_PATH = Path(__file__).resolve().parent.parent / "create-changelog.py"
spec = importlib.util.spec_from_file_location("create_changelog", SCRIPT_PATH)
create_changelog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(create_changelog)


class TestCreateChangelog(unittest.TestCase):

    def test_all_templates_exist(self):
        templates_dir = SCRIPT_PATH.parent.parent / "templates"
        for key, filename in create_changelog.TEMPLATES.items():
            template_path = templates_dir / filename
            self.assertTrue(
                template_path.exists(),
                f"Template '{key}' points to missing file: {template_path}",
            )

    def test_scaffold_substitutes_repo_slug(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            out_path = Path(tmpdir) / "CHANGELOG.md"
            argv = [
                "create-changelog.py",
                "--template",
                "keepachangelog",
                "--repo",
                "acme/widget",
                "--output",
                str(out_path),
            ]
            with patch.object(sys, "argv", argv), patch("sys.stdout", new_callable=io.StringIO):
                create_changelog.main()

            self.assertTrue(out_path.exists())
            content = out_path.read_text(encoding="utf-8")
            self.assertIn("acme/widget", content)
            self.assertNotIn("owner/repo", content)

    def test_existing_file_requires_force(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            out_path = Path(tmpdir) / "CHANGELOG.md"
            out_path.write_text("existing content", encoding="utf-8")

            argv_no_force = [
                "create-changelog.py",
                "--template",
                "keepachangelog",
                "--repo",
                "acme/widget",
                "--output",
                str(out_path),
            ]
            with patch.object(sys, "argv", argv_no_force), patch("sys.stderr", new_callable=io.StringIO):
                with self.assertRaises(SystemExit) as cm:
                    create_changelog.main()
            self.assertEqual(cm.exception.code, 1)
            self.assertEqual(out_path.read_text(encoding="utf-8"), "existing content")

            argv_force = argv_no_force + ["--force"]
            with patch.object(sys, "argv", argv_force), patch("sys.stdout", new_callable=io.StringIO):
                create_changelog.main()
            self.assertIn("acme/widget", out_path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
