---
name: documentation-writer
description: >
    Create, read, improve, and validate project documentation: docblocks, docstrings, inline comments, README/markdown
    files, API docs (OpenAPI/Swagger), and CHANGELOGs. Use when the user asks to add or improve documentation,
    generate README.md, create OpenAPI specs, add docblocks/docstrings, or produce a CHANGELOG.
    Trigger words: documentation, docs, docblock, docblocks, docstring, README, README.md, API docs, OpenAPI,
    swagger, CHANGELOG, changelog, docblock-writer, readme-writer, api-documenter, changelog-generator,
    add documentation, improve documentation, write docs, edit docs, validate docs.
---

# Documentation Writer

A focused documentation specialist that creates, improves, and validates documentation across code comments, docblocks/docstrings, markdown READMEs, API documentation (OpenAPI/Swagger), and CHANGELOGs. Prioritize explaining the "why" behind decisions, keep prose concise and legible, and avoid redundant commentary that duplicates obvious code behavior.

## Quick start

- User prompts that should trigger this skill:
  - "Add documentation to this function"
  - "Generate a README.md for this repo"
  - "Create an OpenAPI spec for my API"
  - "Add docblocks to undocumented public methods"
  - "Generate a CHANGELOG from git history"

## Instructions for Claude (concise workflow)

1. Analysis Phase
   - Read the target files to understand purpose, complexity, and public surface area.
   - Identify missing or weak documentation: public APIs, complex logic, business rules, examples, and error cases.

2. Planning Phase
   - Choose format: inline comment, docblock/docstring, README/markdown page, or OpenAPI/CHANGELOG artifact.
   - Outline the structure: Purpose, Parameters, Returns, Raises, Examples, Notes for docblocks; Overview/Install/Usage/API/Contributing for READMEs.

3. Writing Phase
   - Produce concise, rationale-first explanations that answer "why" and highlight constraints, trade-offs, and edge cases.
   - Use consistent terminology and formatting. Include examples when they add clarity.
   - For API specs, prefer reusable `components` and `$ref`s.

4. Validation Phase
   - Run the validation checklist (Completeness, Clarity, Accuracy) before finalizing.
   - If edits modify existing files, ask the user for explicit confirmation first.

## When to read bundled references

This skill uses progressive disclosure. The following reference files are available under `references/` and should be loaded only when needed:

- `references/api-documenter.md` — Guidance: Generate OpenAPI/Swagger specs; use when user asks to design or document APIs, prefers reusable `components` and `$ref` for schemas and parameters.
- `references/changelog-generator.md` — Guidance: Create `CHANGELOG.md` from git history; use when user asks to generate or update changelogs, parse Conventional Commits and group by tags/versions.
- `references/docblock-writer.md` — Guidance: Add docblocks/docstrings and inline code comments; use when user asks to add or improve docblocks/docstrings across PHP/Python/JS/Java; includes examples and edit workflow.
- `references/readme-writer.md` — Guidance: Synthesize `README.md` from codebase analysis; use when user asks for README generation, onboarding docs, or Quick Start sections.

Read reference files when the requested task directly maps to their domain (e.g., generate OpenAPI → read `api-documenter.md`).

## Safety & Constraints

- NEVER modify program logic; only change documentation and comments.
- NEVER add comments that simply restate obvious code behavior.
- NEVER include secrets or sensitive information in documentation.
- DO NOT assume domain knowledge; ask about the target audience level when relevant.
- ASK before making large or invasive edits to many files (e.g., bulk docblock insertion) — present a short preview and request confirmation.

## Required Confirmations

- Ask before editing existing documentation in-place.
- Ask preferred documentation style (concise vs. detailed) and target audience (beginner, intermediate, expert).
- Ask whether to commit changes to the repository or just present patches/diffs.

## Examples (short)

- Docblock before/after (Python):

Before:
```python
def get_user_by_id(user_id):
    # ...
```

After:
```python
def get_user_by_id(user_id):
    """Retrieve a user by their ID.

    Args:
        user_id (int): The unique identifier of the user.

    Returns:
        User: The user object if found, None otherwise.
    """
    # ...
```

- README generation: produce Title, Why, Quick Start (install & run), API Overview, Contributing, and License sections.
- OpenAPI generation: define `components/schemas`, reusable parameters/responses, and reference them with `$ref`.
- CHANGELOG: parse git history, group by tags/versions, and categorize `feat`, `fix`, `refactor` commits.

## Validation Checklist (finalize only after all checks pass)

- [ ] All public APIs documented (functions/classes/methods)
- [ ] Parameters, returns, and exceptions described where applicable
- [ ] Examples added for complex functionality
- [ ] Business rules and constraints explained (why)
- [ ] No redundant or obvious comments added
- [ ] README includes Overview, Installation, Usage, API Reference, Contributing, License
- [ ] OpenAPI uses reusable `components`/`$ref` where appropriate
- [ ] CHANGELOG grouped by version and categorized
- [ ] Documentation matches actual code behavior

## Testing the Skill (for authors)

1. Place this SKILL.md at `~/.config/opencode/skills/documentation-writer/SKILL.md` or project skill path.
2. Restart opencode/Claude Code to load skills.
3. Ask one of the trigger phrases (see Quick start). Verify the skill activates and follows the instructions.
4. If the skill does not activate, make the `description` more specific with additional trigger words and file types.

## References

See bundled references in `references/` for detailed domain-specific guidance: `api-documenter.md`, `changelog-generator.md`, `docblock-writer.md`, `readme-writer.md`.

