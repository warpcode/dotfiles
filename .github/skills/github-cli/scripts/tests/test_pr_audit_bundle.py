import subprocess
import unittest


class TestPRAuditBundleScript(unittest.TestCase):
    def _extract_issues_from_body(self, body: str) -> list[str]:
        # Pipeline from pr_audit_bundle.sh line 76
        cmd = "grep -oiE '\\b(fix(es|ed)?|close[sd]?|resolve[sd]?)\\b[: ]*#[0-9]+' | grep -oE '[0-9]+' || true"
        res = subprocess.run(
            cmd,
            shell=True,
            input=body,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return res.stdout.strip().splitlines() if res.stdout.strip() else []

    def test_closing_references_various_formats(self):
        test_cases = [
            ("Fixes #123", ["123"]),
            ("fixes: #456", ["456"]),
            ("CLOSED: #789", ["789"]),
            ("resolves#101", ["101"]),
            ("Fixes  #404", ["404"]),
            ("Fixes #1 and Closes: #2", ["1", "2"]),
            ("This PR is a transfix #202 and prefix #303", []),
            ("Status remains unresolved #404", []),
        ]
        for body, expected in test_cases:
            with self.subTest(body=body):
                issues = self._extract_issues_from_body(body)
                self.assertEqual(issues, expected)


if __name__ == "__main__":
    unittest.main()
