"""Structural regression tests for standalone utility and domain skills (#408)."""

from pathlib import Path
import re
import unittest

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / ".github" / "skills"


class TestDomainSkills(unittest.TestCase):
    """Verify issue #408 acceptance criteria across utility and domain skills."""

    def test_adhd_advisor_single_routing_and_no_loops_or_security_block(self) -> None:
        skill_md = (SKILLS_DIR / "adhd-advisor" / "SKILL.md").read_text(encoding="utf-8")
        for forbidden in (
            "Wait(",
            "SECURITY FRAMEWORK",
            "Threat Model",
            "command injection",
            "LOADING STRATEGY",
            "ROUTING LOGIC",
        ):
            self.assertNotIn(forbidden, skill_md, f"Unexpected '{forbidden}' in adhd-advisor/SKILL.md")

        for ref in (
            "adhd-task-strategies.md",
            "adhd-technical-task-breakdowns.md",
            "adhd-real-world-task-breakdowns.md",
        ):
            self.assertEqual(
                len(re.findall(re.escape(ref), skill_md)),
                1,
                f"Expected exactly one routing reference to {ref} in adhd-advisor/SKILL.md",
            )

    def test_email_authoring_extracted_templates_and_no_interview_scripts(self) -> None:
        skill_dir = SKILLS_DIR / "email-authoring"
        skill_md = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
        for forbidden in (
            "How to ask",
            "Never pepper with multiple questions",
            "Just so I can tailor this well",
            "Example wrap-up:",
        ):
            self.assertNotIn(forbidden, skill_md, f"Conversational script '{forbidden}' left in email-authoring/SKILL.md")

        tone_ref = skill_dir / "references" / "tone-and-templates.md"
        self.assertTrue(tone_ref.is_file(), f"Missing {tone_ref}")
        tone_text = tone_ref.read_text(encoding="utf-8").lower()
        for expected in ("tone calibration", "de-escalat", "structural templates"):
            self.assertIn(expected, tone_text)

        self.assertNotIn("## Tone Calibration Summary", skill_md)
        self.assertIn("tone-and-templates.md", skill_md)
        self.assertIn("difficult-emails.md", skill_md)
        self.assertIn("email-classifier", skill_md)

    def test_secrets_vault_classifier_extracted_custom_attributes(self) -> None:
        skill_dir = SKILLS_DIR / "secrets-vault-classifier"
        skill_md = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
        attr_ref = skill_dir / "references" / "custom-attributes-automation.md"
        self.assertTrue(attr_ref.is_file(), f"Missing {attr_ref}")

        attr_text = attr_ref.read_text(encoding="utf-8")
        for field in ("SSH_Host", "LLM_Provider", "ENV_VAR", "Algorithm"):
            self.assertIn(field, attr_text)

        self.assertIn("custom-attributes-automation.md", skill_md)
        self.assertNotIn("## Custom Attribute Schemas", skill_md)
        self.assertIn("## Tag Namespaces", skill_md)
        self.assertIn("## Compatibility Matrix", skill_md)

    def test_html_to_markdown_extracted_obsidian_clippings(self) -> None:
        skill_dir = SKILLS_DIR / "html-to-markdown"
        skill_md = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
        obs_ref = skill_dir / "references" / "obsidian-clippings.md"
        self.assertTrue(obs_ref.is_file(), f"Missing {obs_ref}")

        obs_text = obs_ref.read_text(encoding="utf-8")
        for token in ("==text==", "clippings", "title:", "source:", "author:"):
            self.assertIn(token, obs_text)

        for ref in ("element-mapping.md", "defuddle-options.md", "obsidian-clippings.md"):
            self.assertIn(ref, skill_md)
        self.assertNotIn("## Obsidian-Specific Extensions", skill_md)

    def test_healthy_baseline_skills_intact(self) -> None:
        for skill_name in ("shell-scripting", "natural-writing", "google-antigravity-cli", "youtube"):
            skill_md = SKILLS_DIR / skill_name / "SKILL.md"
            self.assertTrue(skill_md.is_file(), f"Missing {skill_md}")
            text = skill_md.read_text(encoding="utf-8")
            self.assertNotIn("Wait(", text)
            self.assertNotIn("SECURITY FRAMEWORK", text)


if __name__ == "__main__":
    unittest.main()
