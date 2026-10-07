"""Tests for review-pull-request/scripts/build_review_payload.py."""

import json
import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "build_review_payload.py")
)

FINDING = {
    "path": "internal/x.go",
    "line": 12,
    "severity": "High",
    "title": "unchecked error",
    "description": "the error is dropped",
    "impact": "silent data loss",
    "solution": "return the error",
}


def run(spec_text, *args):
    tmp = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    tmp.write(spec_text)
    tmp.close()
    out = tmp.name + ".out"
    try:
        res = subprocess.run(
            [sys.executable, SCRIPT, tmp.name, "--out", out] + list(args),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        payload = None
        if os.path.exists(out):
            with open(out) as fh:
                payload = json.load(fh)
            os.unlink(out)
        return res, payload
    finally:
        os.unlink(tmp.name)


class BuildReviewPayloadTests(unittest.TestCase):
    def test_builds_a_rest_compatible_payload(self):
        res, payload = run(json.dumps([FINDING]))
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(payload["event"], "REQUEST_CHANGES")
        self.assertEqual(len(payload["comments"]), 1)
        c = payload["comments"][0]
        # GitHub rejects these payloads unless they are exactly right:
        # subject_type is GraphQL-only, and side must be RIGHT.
        self.assertNotIn("subject_type", c)
        self.assertEqual(c["side"], "RIGHT")
        self.assertEqual(c["path"], "internal/x.go")
        self.assertEqual(c["line"], 12)

    def test_body_contains_all_four_review_sections(self):
        _, payload = run(json.dumps([FINDING]))
        body = payload["comments"][0]["body"]
        for heading in ("Description", "Impact", "Solution"):
            self.assertIn(heading, body)
        self.assertIn(FINDING["title"], body)

    def test_accepts_object_form_with_findings_key(self):
        res, payload = run(json.dumps({"findings": [FINDING]}))
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(len(payload["comments"]), 1)

    def test_approve_with_no_findings_is_a_valid_payload(self):
        res, payload = run("[]", "--event", "APPROVE")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(payload["event"], "APPROVE")
        self.assertEqual(payload["comments"], [])

    def test_event_choices_are_enforced(self):
        res, _ = run("[]", "--event", "LGTM")
        self.assertNotEqual(res.returncode, 0)

    def test_missing_keys_are_reported_with_their_index(self):
        broken = dict(FINDING)
        del broken["impact"]
        res, payload = run(json.dumps([FINDING, broken]))
        self.assertEqual(res.returncode, 1)
        self.assertIsNone(payload)
        self.assertIn("finding 1", res.stderr)
        self.assertIn("impact", res.stderr)

    def test_line_is_coerced_to_int(self):
        finding = dict(FINDING, line="42")
        _, payload = run(json.dumps([finding]))
        self.assertIsInstance(payload["comments"][0]["line"], int)
        self.assertEqual(payload["comments"][0]["line"], 42)

    def test_custom_body_overrides_the_neutral_default(self):
        _, payload = run(json.dumps([FINDING]), "--body", "custom text")
        self.assertEqual(payload["body"], "custom text")

    def test_multiple_findings_keep_order(self):
        second = dict(FINDING, path="b.go", line=7, title="second")
        _, payload = run(json.dumps([FINDING, second]))
        self.assertEqual(
            [c["path"] for c in payload["comments"]], ["internal/x.go", "b.go"]
        )


if __name__ == "__main__":
    unittest.main()