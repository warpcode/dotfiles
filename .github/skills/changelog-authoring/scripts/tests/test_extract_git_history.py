import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SCRIPT_PATH = Path(__file__).resolve().parent.parent / "extract-git-history.py"
spec = importlib.util.spec_from_file_location("extract_git_history", SCRIPT_PATH)
extract_git_history = importlib.util.module_from_spec(spec)
spec.loader.exec_module(extract_git_history)


class TestExtractGitHistory(unittest.TestCase):

    def test_parse_conventional_commit(self):
        c_type, scope, breaking, msg = extract_git_history.parse_conventional_commit("feat(parser)!: add json streaming")
        self.assertEqual(c_type, "feat")
        self.assertEqual(scope, "parser")
        self.assertTrue(breaking)
        self.assertEqual(msg, "add json streaming")

    def test_extract_pr_number(self):
        self.assertEqual(extract_git_history.extract_pr_number("Fix issue (#123)", ""), 123)
        self.assertEqual(extract_git_history.extract_pr_number("Merge pull request #456 from branch", ""), 456)
        self.assertEqual(extract_git_history.extract_pr_number("Some commit", "Closes #789"), 789)

    def test_classify_commit(self):
        cat, is_breaking, clean_msg, scope = extract_git_history.classify_commit(
            "feat(api): new endpoint (#10)", "", ["feature"]
        )
        self.assertEqual(cat, "Added")
        self.assertFalse(is_breaking)
        self.assertEqual(clean_msg, "new endpoint")
        self.assertEqual(scope, "api")

        cat, is_breaking, clean_msg, scope = extract_git_history.classify_commit(
            "chore: internal cleanup", "", []
        )
        self.assertEqual(cat, "Internal")

    def test_build_provenance_and_changelog(self):
        with patch.object(extract_git_history, "get_commit_sha", side_effect=lambda ref, cwd=None: f"sha_for_{ref}"):
            commits = [
                {
                    "full_sha": "1111111111111111111111111111111111111111",
                    "short_sha": "1111111",
                    "author": "Alice",
                    "date": "2025-01-01",
                    "subject": "feat(core): add core functionality (#42)",
                    "body": "",
                },
                {
                    "full_sha": "2222222222222222222222222222222222222222",
                    "short_sha": "2222222",
                    "author": "Bob",
                    "date": "2025-01-02",
                    "subject": "fix(cli): resolve flag bug (#43)",
                    "body": "",
                },
                {
                    "full_sha": "3333333333333333333333333333333333333333",
                    "short_sha": "3333333",
                    "author": "Charlie",
                    "date": "2025-01-03",
                    "subject": "chore: bump dependency",
                    "body": "",
                },
            ]

            md_output, prov_data = extract_git_history.build_provenance_and_changelog(
                commits=commits,
                from_ref="v1.0.0",
                to_ref="v1.1.0",
                repo_slug="owner/repo",
                version_label="v1.1.0",
                fetch_gh_labels=False,
            )

            self.assertEqual(prov_data["version"], "v1.1.0")
            self.assertEqual(prov_data["commit_count"], 3)
            self.assertEqual(prov_data["prs_included"], [42, 43])
            self.assertEqual(len(prov_data["omitted_or_internal"]), 1)
            self.assertEqual(prov_data["omitted_or_internal"][0]["sha"], "3333333")

            # Markdown checks
            self.assertIn("## [v1.1.0]", md_output)
            self.assertIn("### Added", md_output)
            self.assertIn("### Fixed", md_output)
            self.assertIn("**core**: add core functionality ([#42](https://github.com/owner/repo/pull/42))", md_output)
            self.assertIn("**cli**: resolve flag bug ([#43](https://github.com/owner/repo/pull/43))", md_output)
            self.assertIn("<!--\nchangelog-provenance:", md_output)
            self.assertIn("<details>\n<summary><b>Release Provenance & Audit Trail</b>", md_output)


if __name__ == "__main__":
    unittest.main()
