"""Regression tests for .github/agents/ai-specialist.agent.md (issue #412)."""

import re
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENT_PATH = REPO_ROOT / ".github" / "agents" / "ai-specialist.agent.md"
AI_AUTHORING_SCRIPTS = REPO_ROOT / ".github" / "skills" / "ai-authoring" / "scripts"

if str(AI_AUTHORING_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(AI_AUTHORING_SCRIPTS))

import validate_agents  # noqa: E402
import validate_antigravity  # noqa: E402


class TestAiSpecialistAgent(unittest.TestCase):
    """Verify ai-specialist agent schema compliance, references, and criteria."""

    def test_agent_passes_cross_platform_and_antigravity_validators(self) -> None:
        self.assertTrue(AGENT_PATH.is_file(), f"Missing {AGENT_PATH}")

        agent_results = validate_agents.validate_agent(AGENT_PATH)
        agent_failures = [r for r in agent_results if r[1] == "FAIL"]
        self.assertEqual(agent_failures, [], f"validate_agents failures: {agent_failures}")

        ag_results = validate_antigravity.validate_agent(AGENT_PATH)
        ag_issues = [r for r in ag_results if r[1] in ("FAIL", "WARN")]
        self.assertEqual(ag_issues, [], f"validate_antigravity issues: {ag_issues}")

    def test_frontmatter_loads_unified_skills(self) -> None:
        meta, _ = validate_agents.split_agent_file(AGENT_PATH)
        self.assertEqual(meta.get("name"), "ai-specialist")
        self.assertEqual(meta.get("skills"), ["ai-authoring", "ai-conversation-review"])

    def test_referenced_repo_paths_exist(self) -> None:
        text = AGENT_PATH.read_text(encoding="utf-8")
        # Every explicit .github/skills/... path cited in backticks must exist on origin/master
        cited_paths = sorted(
            set(re.findall(r"(\.github/skills/[A-Za-z0-9_./-]+\.(?:md|py|sh|json))", text))
        )
        self.assertGreater(len(cited_paths), 0, "Expected explicit .github/skills/... citations")
        for rel in cited_paths:
            full = REPO_ROOT / rel
            self.assertTrue(full.exists(), f"Cited path does not exist: {rel}")

        # Verify relative references under ai-authoring/ and ai-conversation-review/ exist
        for rel in re.findall(r"`(references/[A-Za-z0-9_./-]+\.md)`", text):
            in_authoring = (REPO_ROOT / ".github" / "skills" / "ai-authoring" / rel).is_file()
            in_conv = (REPO_ROOT / ".github" / "skills" / "ai-conversation-review" / rel).is_file()
            self.assertTrue(
                in_authoring or in_conv,
                f"Referenced relative guide not found in loaded skills: {rel}",
            )

    def test_covers_acceptance_criteria_and_avoids_stale_pre_407_skills(self) -> None:
        text = AGENT_PATH.read_text(encoding="utf-8")
        for required_phrase in (
            "4-Layer Architecture",
            "Mermaid.js",
            "Bolt",
            "Sentinel",
            "ai-conversation-review",
            "validate.py",
            "validate_agents.py",
            "validate_antigravity.py",
            "./validate.sh",
        ):
            self.assertIn(required_phrase, text, f"Missing '{required_phrase}' in ai-specialist")

        # Pre-#407 retired skill directories must not be referenced as active paths
        for retired in (
            "ai-authoring-skills",
            "ai-authoring-agents",
            "ai-authoring-commands",
            "ai-authoring-rules",
            "ai-authoring-hooks",
            "ai-authoring-prompts",
            "ai-prompts",
        ):
            self.assertNotIn(retired, text, f"Stale pre-#407 reference found: {retired}")


if __name__ == "__main__":
    unittest.main()
