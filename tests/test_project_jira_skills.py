"""Structural regression tests for refactored project-* and jira-* skills."""

from pathlib import Path
import re
import unittest

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / ".github" / "skills"
AGENTS_DIR = REPO_ROOT / ".github" / "agents"


class TestProjectJiraSkills(unittest.TestCase):
    """Verify issue #405 acceptance criteria across project-* and jira-* skills."""

    def test_project_tickets_hierarchy_and_dag_reference(self) -> None:
        dag_ref = SKILLS_DIR / "project-tickets" / "references" / "hierarchy-and-dependency-dags.md"
        self.assertTrue(dag_ref.is_file(), f"Missing {dag_ref}")
        content = dag_ref.read_text(encoding="utf-8").lower()
        for phrase in ("ready frontier", "cycle", "depends on", "blocked by", "stack"):
            self.assertIn(phrase, content, f"Missing '{phrase}' in {dag_ref}")

        skill_md = (SKILLS_DIR / "project-tickets" / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("hierarchy-and-dependency-dags.md", skill_md)

    def test_project_tracker_no_literal_subagent_schemas_and_3way_reconciliation(self) -> None:
        tracker_dir = SKILLS_DIR / "project-tracker"
        for md_file in tracker_dir.rglob("*.md"):
            text = md_file.read_text(encoding="utf-8")
            self.assertNotIn("invoke_subagent", text, f"Found invoke_subagent in {md_file}")
            self.assertNotIn('"TypeName"', text, f'Found "TypeName" in {md_file}')

        skill_md = (tracker_dir / "SKILL.md").read_text(encoding="utf-8")
        self.assertRegex(skill_md, r"Branch\s*/\s*PR")
        self.assertIn("sequencing", skill_md.lower())

    def test_shared_criterion_evidence_verification_reference(self) -> None:
        crit_ref = SKILLS_DIR / "project-tracker" / "references" / "criterion-evidence-verification.md"
        self.assertTrue(crit_ref.is_file(), f"Missing {crit_ref}")

        tracker_skill = (SKILLS_DIR / "project-tracker" / "SKILL.md").read_text(encoding="utf-8")
        jira_assess_skill = (SKILLS_DIR / "jira-issue-assessment" / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("criterion-evidence-verification.md", tracker_skill)
        self.assertIn("criterion-evidence-verification.md", jira_assess_skill)

    def test_project_planner_and_adr_are_declarative(self) -> None:
        forbidden = ("socratic", "grill", "ask_question", "invoke_subagent")
        for skill_name in ("project-planner", "project-adr"):
            skill_text = (SKILLS_DIR / skill_name / "SKILL.md").read_text(encoding="utf-8").lower()
            for token in forbidden:
                self.assertNotIn(token, skill_text, f"Found '{token}' in {skill_name}/SKILL.md")

    def test_project_architect_agent_exists(self) -> None:
        agent_file = AGENTS_DIR / "project-architect.agent.md"
        self.assertTrue(agent_file.is_file(), f"Missing {agent_file}")
        text = agent_file.read_text(encoding="utf-8")
        self.assertRegex(text, r"^---\s*\n[\s\S]*?\bname:\s*project-architect\b[\s\S]*?\n---")
        self.assertIn("Socratic", text)
        self.assertIn("mainAgent: true", text)
        self.assertIn("plain assistant text", text)
        self.assertIn("## Interaction Model", text)

    def test_jira_issue_assessment_rigid_prompt_removed(self) -> None:
        old_template = SKILLS_DIR / "jira-issue-assessment" / "templates" / "assessment-report.md"
        old_validator = SKILLS_DIR / "jira-issue-assessment" / "scripts" / "validate_assessment_report.py"
        self.assertFalse(old_template.exists(), f"Rigid template still exists: {old_template}")
        self.assertFalse(old_validator.exists(), f"Rigid validator still exists: {old_validator}")

        skill_text = (SKILLS_DIR / "jira-issue-assessment" / "SKILL.md").read_text(encoding="utf-8")
        self.assertNotIn("exactly: do not omit", skill_text.lower())

    def test_ticket_templates_make_plan_trailer_optional(self) -> None:
        templates_dir = SKILLS_DIR / "project-tickets" / "templates"
        for name in ("task.md", "story.md"):
            text = (templates_dir / name).read_text(encoding="utf-8")
            self.assertNotIn("| **Plan Link** |", text, f"Mandatory Plan Link in {name}")
            self.assertIn("Traceability (Optional)", text, f"Missing optional Traceability in {name}")
        task_text = (templates_dir / "task.md").read_text(encoding="utf-8")
        self.assertIn("Parent Story / Epic (Optional)", task_text)
        self.assertNotIn("| **Parent Story / Epic** |", task_text)
        parent_line = next(line for line in task_text.splitlines() if "Parent Story / Epic (Optional)" in line)
        self.assertNotIn("docs/plans adapter only", parent_line)
        trace_line = next(line for line in task_text.splitlines() if "Traceability (Optional)" in line)
        self.assertIn("`Closes #...` (issue-first)", trace_line)
        self.assertIn("`Plan: <slug>:<TSK-xxx>` (docs/plans adapter only)", trace_line)


if __name__ == "__main__":
    unittest.main()
