---
name: skill-writer
description: Guide users through creating Agent Skills for AI coding assistants like Claude Code and opencode. Use when the user wants to create, write, author, or design a new Skill, needs help with SKILL.md files, frontmatter, skill structure, troubleshooting skill discovery, or converting existing prompts or workflows into Skills.
---

# Skill Writer

This Skill helps you create well-structured Agent Skills for AI coding assistants like Claude Code and opencode that follow best practices and validation requirements.

## When to use this Skill

Use this Skill when:
- Creating a new Agent Skill
- Writing or updating SKILL.md files
- Designing skill structure and frontmatter
- Troubleshooting skill discovery issues
- Converting existing prompts or workflows into Skills

## Skill Documentation Structure

This skill documentation is organized into reference files for better navigation:

- **Skill Structure and Design**: @references/structure.md - Anatomy of skills, progressive disclosure patterns, bundled resources
- **Skill Creation Process**: @references/creation-process.md - Step-by-step guide to creating and packaging skills
- **Skill Validation and Testing**: @references/validation.md - Testing, debugging, best practices, and examples

**Reference File Linking**: Always use @references/filename.md syntax for referencing files in the references/ subdirectory. Do not use markdown hyperlinks like [text](link).

## Quick Start

To create a new skill:

1. **Plan the skill**: Identify concrete examples and reusable resources
2. **Initialize**: Run `scripts/init_skill.py <name> --path <location>`
3. **Edit**: Write SKILL.md with proper frontmatter and instructions
4. **Test**: Verify the skill activates on relevant queries
5. **Package**: Run `scripts/package_skill.py <skill-folder>` for distribution

For detailed guidance, see the reference files linked above.

---

*Note: Detailed content has been moved to reference files for better organization. See the links above for comprehensive documentation.*
