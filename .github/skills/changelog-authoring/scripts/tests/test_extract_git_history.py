import unittest
from unittest.mock import patch
from pathlib import Path

# Import from extract-git-history.py using importlib or direct import if on PYTHONPATH
import importlib.util
import sys

script_path = Path(__file__).resolve().parent.parent / "extract-git-history.py"
spec = importlib.util.spec_from_file_location("extract_git_history", script_path)
extract_git_history = importlib.util.module_from_spec(spec)
sys.modules["extract_git_history"] = extract_git_history
spec.loader.exec_module(extract_git_history)

ChangelogOptions = extract_git_history.ChangelogOptions
build_provenance_and_changelog = extract_git_history.build_provenance_and_changelog
extract_pr_number = extract_git_history.extract_pr_number
parse_conventional_commit = extract_git_history.parse_conventional_commit
classify_commit = extract_git_history.classify_commit


class TestExtractGitHistory(unittest.TestCase):
    def test_changelog_options_defaults(self):
        opts = ChangelogOptions(
            from_ref="v1.0.0",
            to_ref="HEAD",
            repo_slug="owner/repo",
            version_label="v1.1.0",
        )
        self.assertEqual(opts.from_ref, "v1.0.0")
        self.assertEqual(opts.to_ref, "HEAD")
        self.assertEqual(opts.repo_slug, "owner/repo")
        self.assertEqual(opts.version_label, "v1.1.0")
        self.assertTrue(opts.fetch_gh_labels)
        self.assertIsNone(opts.cwd)

    def test_extract_pr_number(self):
        self.assertEqual(extract_pr_number("feat: new feature (#42)", ""), 42)
        self.assertEqual(extract_pr_number("Merge pull request #101 from dev", ""), 101)
        self.assertEqual(extract_pr_number("Merge PR #202", ""), 202)
        self.assertEqual(extract_pr_number("fix stuff", "Closes #303"), 303)
        self.assertIsNone(extract_pr_number("docs: update readme", "no pr mentioned"))

    def test_parse_conventional_commit(self):
        c_type, scope, breaking, msg = parse_conventional_commit("feat(parser)!: add json streaming")
        self.assertEqual(c_type, "feat")
        self.assertEqual(scope, "parser")
        self.assertTrue(breaking)
        self.assertEqual(msg, "add json streaming")

        c_type, scope, breaking, msg = parse_conventional_commit("fix: correct typo")
        self.assertEqual(c_type, "fix")
        self.assertIsNone(scope)
        self.assertFalse(breaking)
        self.assertEqual(msg, "correct typo")

    def test_classify_commit(self):
        cat, breaking, desc, scope = classify_commit("feat: add feature", "", [])
        self.assertEqual(cat, "Added")
        self.assertFalse(breaking)

        cat, breaking, desc, scope = classify_commit("fix: resolve bug", "", [])
        self.assertEqual(cat, "Fixed")

        cat, breaking, desc, scope = classify_commit("chore: update deps", "", [])
        self.assertEqual(cat, "Internal")

    @patch("extract_git_history.get_commit_sha")
    def test_build_provenance_and_changelog(self, mock_get_commit_sha):
        mock_get_commit_sha.side_effect = lambda ref, cwd=None: f"sha_for_{ref}"

        commits = [
            {
                "full_sha": "1234567890123456789012345678901234567890",
                "short_sha": "1234567",
                "author": "Alice",
                "date": "2025-01-01",
                "subject": "feat(api): add new endpoint (#10)",
                "body": "",
            },
            {
                "full_sha": "abcdef0123456789abcdef0123456789abcdef01",
                "short_sha": "abcdef0",
                "author": "Bob",
                "date": "2025-01-02",
                "subject": "chore: bump dependency version",
                "body": "",
            },
        ]

        options = ChangelogOptions(
            from_ref="v1.0.0",
            to_ref="v1.1.0",
            repo_slug="owner/repo",
            version_label="1.1.0",
            fetch_gh_labels=False,
        )

        md, prov = build_provenance_and_changelog(commits, options)

        self.assertIn("## [1.1.0]", md)
        self.assertIn("### Added", md)
        self.assertIn("**api**: add new endpoint ([#10](https://github.com/owner/repo/pull/10))", md)
        self.assertEqual(prov["version"], "1.1.0")
        self.assertEqual(prov["commit_count"], 2)
        self.assertEqual(prov["base_commit"], "sha_for_v1.0.0")
        self.assertEqual(prov["head_commit"], "sha_for_v1.1.0")
        self.assertEqual(prov["prs_included"], [10])


if __name__ == "__main__":
    unittest.main()
