#!/usr/bin/env python3
"""Unit tests for audit_repo_alerts.py.

    python3 -m unittest discover -s tests
"""

import importlib.util
import pathlib
import sys
import unittest
from unittest import mock

SCRIPT = pathlib.Path(__file__).resolve().parent.parent / "audit_repo_alerts.py"
spec = importlib.util.spec_from_file_location("audit_repo_alerts", SCRIPT)
alerts = importlib.util.module_from_spec(spec)
sys.modules["audit_repo_alerts"] = alerts
spec.loader.exec_module(alerts)


class TestResolveRepo(unittest.TestCase):
    def test_parses_ssh_remote(self):
        with mock.patch.object(alerts, "run",
                               return_value=(0, "git@github.com:warpcode/dotfiles.git\n", "")):
            self.assertEqual(alerts.resolve_repo(None), "warpcode/dotfiles")

    def test_parses_https_remote(self):
        with mock.patch.object(alerts, "run",
                               return_value=(0, "https://github.com/warpcode/dotfiles\n", "")):
            self.assertEqual(alerts.resolve_repo(None), "warpcode/dotfiles")

    def test_explicit_repo_wins(self):
        self.assertEqual(alerts.resolve_repo("a/b"), "a/b")

    def test_unparseable_remote_exits(self):
        with mock.patch.object(alerts, "run", return_value=(0, "not-a-url\n", "")):
            with self.assertRaises(SystemExit):
                alerts.resolve_repo(None)


class TestFileExistsOnRef(unittest.TestCase):
    """Existence check that a zsh loop can silently defeat -- see module notes."""

    def test_true_when_present(self):
        with mock.patch.object(alerts, "run", return_value=(0, "", "")):
            self.assertTrue(alerts.file_exists_on_ref("origin/master", "a/b.py"))

    def test_false_when_absent(self):
        with mock.patch.object(alerts, "run", return_value=(1, "", "")):
            self.assertFalse(alerts.file_exists_on_ref("origin/master", "a/b.py"))


class TestDependabotClassification(unittest.TestCase):
    def _alert(self, **kw):
        a = {
            "number": 1, "state": "open",
            "security_advisory": {"severity": "high", "ghsa_id": "GHSA-x",
                                  "summary": "s"},
            "dependency": {"package": {"name": "urllib3"},
                           "manifest_path": "uv.lock"},
            "security_vulnerabilities": [{"first_patched_version": None}],
        }
        a.update(kw)
        return a

    def test_unpatched_alert_does_not_raise(self):
        """Regression: next() without a default raised StopIteration on exactly
        the first_patched_version: NONE case this script exists to report."""
        with mock.patch.object(alerts, "file_exists_on_ref", return_value=True):
            rows = alerts.classify_dependabot([self._alert()], "origin/master")
        self.assertEqual(len(rows), 1)
        self.assertFalse(rows[0]["fix_available"])
        self.assertIsNone(rows[0]["fixed_in"])

    def test_patched_alert_records_version(self):
        a = self._alert(security_vulnerabilities=[
            {"first_patched_version": {"identifier": "2.7.1"}}])
        with mock.patch.object(alerts, "file_exists_on_ref", return_value=True):
            rows = alerts.classify_dependabot([a], "origin/master")
        self.assertTrue(rows[0]["fix_available"])
        self.assertEqual(rows[0]["fixed_in"], "2.7.1")

    def test_empty_vulnerability_list_does_not_raise(self):
        with mock.patch.object(alerts, "file_exists_on_ref", return_value=True):
            rows = alerts.classify_dependabot(
                [self._alert(security_vulnerabilities=[])], "origin/master")
        self.assertFalse(rows[0]["fix_available"])

    def test_missing_manifest_marked_absent(self):
        with mock.patch.object(alerts, "file_exists_on_ref", return_value=False):
            rows = alerts.classify_dependabot([self._alert()], "origin/master")
        self.assertFalse(rows[0]["manifest_exists"])


class TestAlertRender(unittest.TestCase):
    def _dep(self, number, exists, ghsa="GHSA-x", state="open"):
        return {"number": number, "state": state, "severity": "high", "ghsa": ghsa,
                "summary": "sum", "package": "urllib3", "manifest": f"m{number}.lock",
                "manifest_exists": exists, "fix_available": False,
                "fixed_in": None, "dismissed_reason": None}

    def test_phantoms_listed_with_dismiss_commands(self):
        dep = [self._dep(5, False), self._dep(6, False), self._dep(2, True)]
        out = alerts.render(dep, [], "o/r", "master")
        self.assertIn("## Phantom alerts", out)
        self.assertIn("alerts/5", out)
        self.assertIn("alerts/6", out)
        self.assertIn("280 characters", out)
        self.assertIn("## Real alerts", out)

    def test_dismiss_comment_is_within_api_limit(self):
        """The API caps dismissed_comment at 280 chars; emit a comment that fits."""
        dep = [self._dep(5, False), self._dep(2, True)]
        out = alerts.render(dep, [], "warpcode/dotfiles", "master")
        for line in out.splitlines():
            if "dismissed_comment=" in line:
                comment = line.split("dismissed_comment=", 1)[1].rstrip("'")
                self.assertLessEqual(len(comment), 280, comment)

    def test_triplication_is_summarised(self):
        dep = [self._dep(2, True), self._dep(3, False), self._dep(4, False)]
        out = alerts.render(dep, [], "o/r", "master")
        self.assertIn("Duplicate advisories across manifests", out)
        self.assertIn("3x", out)

    def test_unfixable_counted(self):
        out = alerts.render([self._dep(2, True)], [], "o/r", "master")
        self.assertIn("no upgrade exists yet", out)

    def test_no_open_code_scanning_states_cleanly(self):
        self.assertIn("No open alerts", alerts.render([], [], "o/r", "master"))

    def test_valid_dismissal_reasons_listed(self):
        cs = [{"number": 4, "state": "open",
               "rule": {"severity": "error", "id": "py/command-line-injection"},
               "most_recent_instance": {"location": {"path": "a.py", "start_line": 3}}}]
        out = alerts.render([], cs, "o/r", "master")
        self.assertIn("py/command-line-injection", out)
        self.assertIn("a.py", out)
        self.assertIn("false positive", out)


if __name__ == "__main__":
    unittest.main()