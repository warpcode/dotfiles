"""Structural regression tests for .github/agents/epic-orchestrator.agent.md (issue #409)."""

from pathlib import Path
import re
import subprocess
import sys
import unittest

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = REPO_ROOT / ".github" / "agents"
AUTHORING_SCRIPTS = REPO_ROOT / ".github" / "skills" / "ai-authoring" / "scripts"
AGENT_FILE = AGENTS_DIR / "epic-orchestrator.agent.md"


class TestEpicOrchestratorAgent(unittest.TestCase):
    """Verify issue #409 acceptance criteria for epic-orchestrator.agent.md."""

    def test_agent_exists_and_has_valid_frontmatter(self) -> None:
        self.assertTrue(AGENT_FILE.is_file(), f"Missing {AGENT_FILE}")
        text = AGENT_FILE.read_text(encoding="utf-8")
        self.assertRegex(
            text,
            r"^---\s*\n[\s\S]*?\bname:\s*epic-orchestrator\b[\s\S]*?\n---",
        )
        self.assertIn("subagent: true", text)
        self.assertIn("mainAgent: true", text)
        self.assertIn("invoke_subagent", text)

    def test_passes_agent_validators(self) -> None:
        for script_name in ("validate_agents.py", "validate_antigravity.py"):
            script = AUTHORING_SCRIPTS / script_name
            proc = subprocess.run(
                [sys.executable, str(script), str(AGENT_FILE)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(
                proc.returncode,
                0,
                f"{script_name} failed:\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}",
            )

    def test_references_consolidated_knowledge_centres(self) -> None:
        text = AGENT_FILE.read_text(encoding="utf-8")
        for skill_ref in (
            "git-expert/",
            "github/",
            "project-tickets/",
            "project-tracker/",
        ):
            self.assertIn(skill_ref, text, f"Missing reference to {skill_ref}")

        for legacy_skill in ("github-pr/", "github-issues/", "github-cli/"):
            self.assertNotIn(
                legacy_skill,
                text,
                f"Legacy pre-#403 skill path {legacy_skill} should be consolidated under github/",
            )

    def test_supports_both_branching_modes_and_dag_gating(self) -> None:
        text = AGENT_FILE.read_text(encoding="utf-8")
        self.assertIn("Epic-Tree", text)
        self.assertIn("Dependency-Stacked", text)
        self.assertIn("Mainline", text)
        self.assertIn("Ready Frontier", text)
        self.assertIn("Depends on #N", text)
        self.assertIn("Blocked by #N", text)
        self.assertIn("branch_base_check.sh", text)

    def test_delegates_to_software_engineer_and_code_reviewer(self) -> None:
        text = AGENT_FILE.read_text(encoding="utf-8")
        self.assertIn("software-engineer", text)
        self.assertIn("code-reviewer", text)
        self.assertIn("worktree", text.lower())
        self.assertIn("baseRefName", text)
        self.assertRegex(text, r"(?i)three-way|3-way")


if __name__ == "__main__":
    unittest.main()
