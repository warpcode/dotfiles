import json
import subprocess
import unittest
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve().parent.parent / "pr_audit_bundle.sh"


class TestPRAuditBundleScript(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        content = SCRIPT_PATH.read_text()
        cls.grep_pipeline = None
        for line in content.splitlines():
            if "grep -oiE" in line and "fix(es|ed)" in line:
                cls.grep_pipeline = line[line.find("grep -oiE"):].strip()
                break
        if not cls.grep_pipeline:
            raise RuntimeError("Could not find issue regex line in pr_audit_bundle.sh")

    def _extract_issues_from_body(self, body: str) -> list[str]:
        # Execute the exact pipeline extracted from pr_audit_bundle.sh
        cmd = f"jq -r '.body // \"\"' | {self.grep_pipeline}"
        json_input = json.dumps({"body": body})
        res = subprocess.run(
            cmd,
            shell=True,
            input=json_input,
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
            ("This PR fixes #606.", ["606"]),
            ("This PR is a transfix #202 and prefix #303", []),
            ("Status remains unresolved #404", []),
            ("(Fixes #123)", ["123"]),
            ("[Closes #456]", ["456"]),
            ("Fixes #10, closes #12", ["10", "12"]),
        ]
        for body, expected in test_cases:
            with self.subTest(body=body):
                issues = self._extract_issues_from_body(body)
                self.assertEqual(issues, expected)


if __name__ == "__main__":
    unittest.main()
