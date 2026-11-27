"""Structural regression tests for the code-reviewer agent and code-review prompt."""

from pathlib import Path
import sys
import unittest

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENT_PATH = REPO_ROOT / ".github" / "agents" / "code-reviewer.agent.md"
PROMPT_PATH = REPO_ROOT / ".github" / "prompts" / "code-review.prompt.md"
AI_SCRIPTS_DIR = REPO_ROOT / ".github" / "skills" / "ai-authoring" / "scripts"

if str(AI_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(AI_SCRIPTS_DIR))

import validate_agents  # noqa: E402
import validate_antigravity  # noqa: E402
import validate_commands  # noqa: E402


class TestCodeReviewerAgentAndPrompt(unittest.TestCase):
    """Verify issue #410 acceptance criteria for code-reviewer and code-review prompt."""

    def test_agent_passes_validators(self) -> None:
        agent_res = validate_agents.validate_agent(AGENT_PATH)
        self.assertFalse(
            any(status == "FAIL" for _, status, _ in agent_res),
            f"validate_agents failed: {agent_res}",
        )
        ag_res = validate_antigravity.validate_agent(AGENT_PATH)
        self.assertFalse(
            any(status == "FAIL" for _, status, _ in ag_res),
            f"validate_antigravity failed: {ag_res}",
        )
        self.assertFalse(
            any(status == "WARN" for _, status, _ in ag_res),
            f"validate_antigravity warned: {ag_res}",
        )

    def test_prompt_passes_command_validator(self) -> None:
        cmd_res = validate_commands.validate_command_file(PROMPT_PATH)
        self.assertFalse(
            any(status == "FAIL" for _, status, _ in cmd_res),
            f"validate_commands failed: {cmd_res}",
        )

    def test_agent_composes_knowledge_centres_without_stale_skills(self) -> None:
        text = AGENT_PATH.read_text(encoding="utf-8")
        for stale in ("github-pr-review", "github-cli", "github-pr"):
            self.assertNotIn(stale, text, f"Stale skill reference '{stale}' in {AGENT_PATH}")

        for skill in (
            "github",
            "code-review",
            "code-security-audit",
            "code-architecture",
            "code-performance",
            "git-expert",
        ):
            self.assertIn(skill, text, f"Missing knowledge centre '{skill}' in {AGENT_PATH}")

        for script in (
            "github/scripts/pr_audit_bundle.sh",
            "github/scripts/prebundle_prs.sh",
            "github/scripts/list_pull_request_review_threads.sh",
            "github/scripts/update_pull_request_review_thread_resolution.sh",
            "github/scripts/reply_to_review_thread.sh",
            "github/scripts/verify_review_anchors.sh",
            "github/scripts/submit_review.sh",
            "git-expert/scripts/audit_repo_branches.py",
            "git-expert/scripts/branch_base_check.sh",
            "code-review/scripts/mutation_check.sh",
            "code-review/scripts/audit_ci_test_coverage.sh",
        ):
            self.assertIn(script, text, f"Missing script reference '{script}' in {AGENT_PATH}")
            self.assertTrue(
                (REPO_ROOT / ".github" / "skills" / script).is_file(),
                f"Referenced script does not exist on disk: {script}",
            )

    def test_agent_owns_four_phase_pipeline_and_disposition_policy(self) -> None:
        text = AGENT_PATH.read_text(encoding="utf-8")
        for heading in (
            "### Phase 1: Gather & Scope",
            "### Phase 2: Audit & Mutate-Verify",
            "### Phase 3: Reconcile Review Threads",
            "### Phase 4: Disposition & Submit",
        ):
            self.assertIn(heading, text, f"Missing pipeline phase '{heading}'")

        for token in (
            "baseRefName",
            "REQUEST_CHANGES",
            "APPROVE",
            '--body ""',
            "COMMENT",
            "parallel",
        ):
            self.assertIn(token, text, f"Missing expected policy/pipeline token '{token}'")

    def test_prompt_delegates_to_code_reviewer_without_stale_coupling(self) -> None:
        text = PROMPT_PATH.read_text(encoding="utf-8")
        meta, _body = validate_commands.split_command_file(PROMPT_PATH)
        self.assertEqual(meta.get("agent"), "code-reviewer")
        for stale in ("github-pr-review", "github-cli", "github-pr"):
            self.assertNotIn(stale, text, f"Stale skill reference '{stale}' in {PROMPT_PATH}")
        self.assertIn("code-reviewer", text)
        self.assertIn("baseRefName", text)


if __name__ == "__main__":
    unittest.main()
