import importlib.util
import sys
import unittest
from pathlib import Path

# Load audit-changelog.py dynamically since it uses hyphens in filename
script_path = Path(__file__).parent.parent / "audit-changelog.py"
spec = importlib.util.spec_from_file_location("audit_changelog", script_path)
audit_changelog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit_changelog)


class TestGenerateMarkdownReport(unittest.TestCase):
    def test_report_generation_with_missing_commits(self):
        entries = [
            {"version": "1.0.0", "date": "2025-01-01"},
            {"version": "0.9.0", "date": "2024-12-01"},
        ]
        audit_results = [
            {
                "version": "1.0.0",
                "missing_commits": [
                    {
                        "short_sha": "a1b2c3d",
                        "author": "Alice",
                        "subject": "feat: new feature",
                        "severity": "High",
                    }
                ],
                "format_ok": True,
                "git_commit_count": 10,
                "audited_commit_count": 9,
            },
            {
                "version": "0.9.0",
                "missing_commits": [],
                "format_ok": True,
                "git_commit_count": 5,
                "audited_commit_count": 5,
            },
        ]
        continuity_findings = [
            {
                "from_version": "1.0.0",
                "to_version": "0.9.0",
                "gap": "base_commit (1234567) != predecessor head_commit (7654321)",
            }
        ]

        report = audit_changelog.generate_markdown_report(
            Path("CHANGELOG.md"), entries, audit_results, continuity_findings
        )

        self.assertIn("# Changelog Audit Report: `CHANGELOG.md`", report)
        self.assertIn("| `1.0.0` | 2025-01-01 | FAIL | 10 | 9 | 1 |", report)
        self.assertIn("| `0.9.0` | 2024-12-01 | PASS | 5 | 5 | 0 |", report)
        self.assertIn("| `a1b2c3d` | Alice | feat: new feature | **High** |", report)
        self.assertIn("| `1.0.0` | `0.9.0` | base_commit (1234567) != predecessor head_commit (7654321) |", report)

    def test_report_generation_zero_missing(self):
        entries = [{"version": "1.0.0", "date": "2025-01-01"}]
        audit_results = [
            {
                "version": "1.0.0",
                "missing_commits": [],
                "format_ok": True,
                "git_commit_count": 10,
                "audited_commit_count": 10,
            }
        ]
        report = audit_changelog.generate_markdown_report(
            Path("CHANGELOG.md"), entries, audit_results, []
        )
        self.assertIn("✅ **Zero missing commits detected.**", report)


if __name__ == "__main__":
    unittest.main()
