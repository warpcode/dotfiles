"""Structural regression tests for issue #413 agents, prompt workflows, and chezmoi symlinks."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = REPO_ROOT / ".github" / "agents"
PROMPTS_DIR = REPO_ROOT / ".github" / "prompts"
SKILLS_DIR = REPO_ROOT / ".github" / "skills"
COMMANDS_JSON_PATH = REPO_ROOT / ".chezmoidata" / "commands.json"
CHEZMOI_AVAILABLE = shutil.which("chezmoi") is not None


class TestAgentAndPromptAlignment(unittest.TestCase):
    """Verify issue #413 acceptance criteria for agents, prompts, and chezmoi agent symlinks."""

    def test_software_engineer_agent_bindings_and_worktree_protocol(self) -> None:
        agent_file = AGENTS_DIR / "software-engineer.agent.md"
        self.assertTrue(agent_file.is_file(), f"Missing {agent_file}")
        text = agent_file.read_text(encoding="utf-8")

        required_skills = (
            "coding",
            "code-tdd",
            "code-architecture",
            "code-performance",
            "code-security-audit",
            "database-architecture",
            "shell-scripting",
            "git-expert",
            "github",
        )
        for skill in required_skills:
            self.assertIn(skill, text, f"Missing skill binding '{skill}' in software-engineer.agent.md")

        for phrase in ("epic/<id>-<slug>", "branch_base_check.sh", "./validate.sh", "--base"):
            self.assertIn(phrase, text, f"Missing '{phrase}' in software-engineer.agent.md")

    def test_git_specialist_agent_consolidated_skills_and_workflows(self) -> None:
        agent_file = AGENTS_DIR / "git-specialist.agent.md"
        self.assertTrue(agent_file.is_file(), f"Missing {agent_file}")
        text = agent_file.read_text(encoding="utf-8")

        for obsolete in ("github-pr", "github-issues", "github-cli", "github-dependabot", "git-commit", "git-worktrees"):
            self.assertNotIn(obsolete, text, f"Found unconsolidated skill name '{obsolete}' in git-specialist.agent.md")

        for required in ("git-expert", "github", "audit_repo_branches.py", "branch_base_check.sh", "merge_state.sh", "--onto"):
            self.assertIn(required, text, f"Missing '{required}' in git-specialist.agent.md")

    def test_project_lifecycle_prompt_has_no_phantom_agents(self) -> None:
        prompt_file = PROMPTS_DIR / "project-lifecycle.prompt.md"
        self.assertTrue(prompt_file.is_file(), f"Missing {prompt_file}")
        text = prompt_file.read_text(encoding="utf-8")

        phantom_names = (
            "planner-agent",
            "ticket-creator",
            "code-creator",
            "swagger-checker",
            "style-guide-checker",
            "bug-finder",
            "sql-analyzer",
            "security-auditor",
            "review-coordinator",
            "merge-coordinator",
            "get_pull_request.sh",
        )
        for phantom in phantom_names:
            self.assertNotIn(phantom, text, f"Found phantom reference '{phantom}' in project-lifecycle.prompt.md")

        real_agents = (
            "project-architect",
            "epic-orchestrator",
            "software-engineer",
            "code-reviewer",
            "git-specialist",
        )
        for agent in real_agents:
            self.assertIn(agent, text, f"Missing real agent '{agent}' in project-lifecycle.prompt.md")

        self.assertIn("Mainline", text)
        self.assertIn("Epic-Tree", text)

    def test_agent_and_command_validators_pass(self) -> None:
        scripts_dir = SKILLS_DIR / "ai-authoring" / "scripts"
        for validator, target in (
            ("validate_agents.py", AGENTS_DIR),
            ("validate_antigravity.py", AGENTS_DIR),
            ("validate_commands.py", PROMPTS_DIR),
        ):
            res = subprocess.run(
                ["python3", str(scripts_dir / validator), str(target)],
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(
                res.returncode,
                0,
                f"{validator} failed on {target}:\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}",
            )

    def test_commands_json_includes_validate_and_master_merge(self) -> None:
        data = json.loads(COMMANDS_JSON_PATH.read_text(encoding="utf-8"))
        allow = data["commands"]["allow"]
        self.assertIn("./validate.sh", allow)
        self.assertIn("git merge origin/master", allow)

    def test_chezmoi_agent_symlink_templates_exist(self) -> None:
        expected = f"{REPO_ROOT}/.github/agents/"
        for rel in ("dot_agents/symlink_agents.tmpl", "dot_gemini/config/symlink_agents.tmpl"):
            tmpl_path = REPO_ROOT / rel
            self.assertTrue(tmpl_path.is_file(), f"Missing {tmpl_path}")
            self.assertEqual(tmpl_path.read_text(encoding="utf-8"), "{{ .chezmoi.sourceDir }}/.github/agents/")
            if CHEZMOI_AVAILABLE:
                out = subprocess.check_output(
                    [
                        "chezmoi",
                        "--source",
                        str(REPO_ROOT),
                        "--persistent-state",
                        "/tmp/chezmoitest.boltdb",
                        "execute-template",
                        tmpl_path.read_text(encoding="utf-8"),
                    ],
                    cwd=REPO_ROOT,
                    text=True,
                )
                self.assertEqual(out, expected)
                self.assertTrue(os.path.isdir(out.rstrip("/")))


if __name__ == "__main__":
    unittest.main()
