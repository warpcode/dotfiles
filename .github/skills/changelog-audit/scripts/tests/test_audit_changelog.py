import importlib.util
import unittest
from pathlib import Path
import sys

# Load audit-changelog.py dynamically since it has a hyphen in filename
script_path = Path(__file__).resolve().parent.parent / "audit-changelog.py"
spec = importlib.util.spec_from_file_location("audit_changelog", script_path)
audit_changelog = importlib.util.module_from_spec(spec)
sys.modules["audit_changelog"] = audit_changelog
spec.loader.exec_module(audit_changelog)

parse_provenance_block = audit_changelog.parse_provenance_block
parse_changelog = audit_changelog.parse_changelog
check_continuity = audit_changelog.check_continuity
generate_markdown_report = audit_changelog.generate_markdown_report
load_changelog_entries = audit_changelog.load_changelog_entries
print_terminal_summary = audit_changelog.print_terminal_summary


class TestAuditChangelog(unittest.TestCase):
    def test_parse_provenance_block(self):
        text = """
<!-- changelog-provenance:
commit_range: v1.0.0..v1.1.0
base_commit: abc1234
head_commit: def5678
prs_included: [101, 102]
labels_recorded:
    enhancement: [101]
    bug: [102]
omitted_or_internal:
    - sha: 1112223
      reason: "chore: update deps"
-->
"""
        prov = parse_provenance_block(text)
        self.assertIsNotNone(prov)
        self.assertEqual(prov["commit_range"], "v1.0.0..v1.1.0")
        self.assertEqual(prov["base_commit"], "abc1234")
        self.assertEqual(prov["head_commit"], "def5678")
        self.assertEqual(prov["prs_included"], [101, 102])
        self.assertEqual(prov["labels_recorded"], {"enhancement": [101], "bug": [102]})
        self.assertEqual(
            prov["omitted_or_internal"],
            [{"sha": "1112223", "reason": "chore: update deps"}],
        )

    def test_parse_provenance_block_none(self):
        self.assertIsNone(parse_provenance_block("No provenance here"))

    def test_parse_changelog(self):
        content = """# Changelog

## [1.1.0] - 2026-01-15
### Features
- Support new widget [#101] and (#102)

### Breaking Changes
⚠️ API changed

<!-- changelog-provenance:
commit_range: v1.0.0..v1.1.0
-->

## [1.0.0] - 2026-01-01
- Initial release [#99]
"""
        entries = parse_changelog(content)
        self.assertEqual(len(entries), 2)

        e0 = entries[0]
        self.assertEqual(e0["version"], "1.1.0")
        self.assertEqual(e0["date"], "2026-01-15")
        self.assertEqual(e0["prs_in_text"], [101, 102])
        self.assertTrue(e0["has_breaking"])
        self.assertIsNotNone(e0["provenance"])

        e1 = entries[1]
        self.assertEqual(e1["version"], "1.0.0")
        self.assertEqual(e1["date"], "2026-01-01")
        self.assertEqual(e1["prs_in_text"], [99])
        self.assertFalse(e1["has_breaking"])

    def test_check_continuity(self):
        entries = [
            {
                "version": "1.2.0",
                "provenance": {
                    "base_commit": "def5678",
                    "head_commit": "7890abc",
                },
            },
            {
                "version": "1.1.0",
                "provenance": {
                    "base_commit": "abc1234",
                    "head_commit": "def5678",
                },
            },
        ]
        gaps = check_continuity(entries)
        self.assertEqual(len(gaps), 0)

        # Gap scenario
        entries_gap = [
            {
                "version": "1.2.0",
                "provenance": {
                    "base_commit": "xxxxxxx",
                    "head_commit": "7890abc",
                },
            },
            {
                "version": "1.1.0",
                "provenance": {
                    "base_commit": "abc1234",
                    "head_commit": "def5678",
                },
            },
        ]
        gaps = check_continuity(entries_gap)
        self.assertEqual(len(gaps), 1)

    def test_generate_markdown_report(self):
        cl_path = Path("CHANGELOG.md")
        entries = [{"version": "1.0.0", "date": "2026-01-01"}]
        results = [{
            "version": "1.0.0",
            "has_provenance": True,
            "format_ok": True,
            "git_commit_count": 5,
            "audited_commit_count": 5,
            "missing_commits": [],
        }]
        report = generate_markdown_report(cl_path, entries, results, [])
        self.assertIn("# Changelog Audit Report: `CHANGELOG.md`", report)
        self.assertIn("PASS", report)

    def test_load_changelog_entries(self):
        import tempfile
        content = """# Changelog

## [1.1.0] - 2026-01-15
- Feature test

## [1.0.0] - 2026-01-01
- Initial release
"""
        with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".md") as tmp:
            tmp.write(content)
            tmp_path = Path(tmp.name)

        try:
            entries, targets = load_changelog_entries(tmp_path)
            self.assertEqual(len(entries), 2)
            self.assertEqual(len(targets), 2)

            entries, targets_ver = load_changelog_entries(tmp_path, target_version="1.1.0")
            self.assertEqual(len(entries), 2)
            self.assertEqual(len(targets_ver), 1)
            self.assertEqual(targets_ver[0]["version"], "1.1.0")
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    def test_print_terminal_summary(self):
        results_pass = [{
            "version": "1.0.0",
            "has_provenance": True,
            "format_ok": True,
            "git_commit_count": 5,
            "audited_commit_count": 5,
            "missing_commits": [],
            "format_errors": [],
        }]
        has_failures = print_terminal_summary("CHANGELOG.md", results_pass, [])
        self.assertFalse(has_failures)

        results_fail = [{
            "version": "1.0.0",
            "has_provenance": False,
            "format_ok": False,
            "git_commit_count": 5,
            "audited_commit_count": 4,
            "missing_commits": [{
                "short_sha": "abc1234",
                "author": "Alice",
                "subject": "feat: new feature",
                "severity": "High",
            }],
            "format_errors": ["Missing date"],
        }]
        has_failures_fail = print_terminal_summary("CHANGELOG.md", results_fail, [])
        self.assertTrue(has_failures_fail)


if __name__ == "__main__":
    unittest.main()
