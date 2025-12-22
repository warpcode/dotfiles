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

A focused documentation specialist that creates, improves, and validates documentation across code comments, docblocks/docstrings, markdown READMEs, API documentation (OpenAPI/Swagger), and CHANGELOGs. Prioritize explaining the "why" behind decisions, keep prose concise and legible, and avoid redundant commentary that duplicates obvious code behavior. Emphasize rationale over implementation details, focusing on business logic, constraints, and non-obvious choices.

## Quick start

- User prompts that should trigger this skill:
  - "Add documentation to this function"
  - "Generate a README.md for this repo"
  - "Create an OpenAPI spec for my API"
  - "Add docblocks to undocumented public methods"
  - "Generate a CHANGELOG from git history"

## Workflow

1. **Analysis Phase**
   - Read target files to understand purpose, complexity, and public surface area.
   - Identify missing/weak documentation: public APIs, complex logic, business rules, examples, error cases.

2. **Planning Phase**
   - Choose format: inline comment, docblock/docstring, README/markdown, or OpenAPI/CHANGELOG.
   - Outline structure: Purpose/Parameters/Returns/Raises/Examples/Notes for docblocks; Overview/Install/Usage/API/Contributing for READMEs.

3. **Writing Phase**
   - Produce concise, rationale-first explanations answering "why" with constraints, trade-offs, edge cases.
   - Use consistent terminology/formatting. Include examples for clarity.
   - For API specs, prefer reusable `components` and `$ref`s.

4. **Validation Phase**
   - Run validation checklist (Completeness, Clarity, Accuracy) before finalizing.
   - If edits modify existing files, ask user for explicit confirmation first.

## When to read bundled references

This skill uses progressive disclosure. The following reference files are available under `references/` and should be loaded only when needed:

- `references/api-documenter.md` — Guidance: Generate OpenAPI/Swagger specs; use when user asks to design or document APIs, prefers reusable `components` and `$ref` for schemas and parameters.
- `references/changelog-generator.md` — Guidance: Create `CHANGELOG.md` from git history; use when user asks to generate or update changelogs, parse Conventional Commits and group by tags/versions.
- `references/docblock-writer.md` — Guidance: Add docblocks/docstrings and inline code comments; use when user asks to add or improve docblocks/docstrings across PHP/Python/JS/Java; includes examples and edit workflow.
- `references/readme-writer.md` — Guidance: Synthesize `README.md` from codebase analysis; use when user asks for README generation, onboarding docs, or Quick Start sections.

Read reference files when the requested task directly maps to their domain (e.g., generate OpenAPI → read `api-documenter.md`).

## Documentation Standards

**Focus: Explain WHY, not WHAT or HOW.** Comments should exist only when rationale is not obvious—code shows WHAT/HOW.

- **Inline Comments:** For business rules, performance, security. E.g., explain constraints like GDPR compliance.
- **Docblocks/Docstrings:** Structure with Purpose, Parameters, Returns, Raises, Examples, Notes. Avoid redundant descriptions.
- **Markdown/Wiki:** Clear headings, consistent formatting, explain "why" for APIs/projects.

## Examples

- **Business Rule (GDPR Compliance):**
  ```python
  # GDPR requires user data deletion within 30 days of account closure.
  # Soft deletion maintains audit trails while complying with privacy regulations.
  user.deleted_at = datetime.now()
  ```

- **Security Rationale:**
  ```python
  # Hash passwords with bcrypt (not MD5) for computational hardness against brute-force attacks.
  # MD5 is cryptographically broken and unsafe for password storage.
  hashed_password = bcrypt.hash(password)
  ```

- **Performance Consideration:**
  ```python
  def process_bulk_orders(orders, options=None):
      """
      Process multiple orders with optimized batch operations.

      Process in batches of 100 to balance memory usage with database performance.
      Individual processing would be too slow; all-at-once causes exhaustion.
      Batch size determined through testing.

      Args:
          orders (list): List of order dictionaries
          options (dict, optional): Processing options

      Returns:
          dict: Processing results with successful/failed counts

      Raises:
          BulkProcessingError: If >10% orders fail
      """
  ```

## Safety & Constraints

- NEVER modify program logic; only documentation/comments.
- NEVER add comments restating obvious code (e.g., "# Create user object" for `user = User()`).
- NEVER include secrets/sensitive info in docs.
- NEVER create docs contradicting code.
- NEVER assume domain knowledge—explain technical concepts.
- ASK before large/invasive edits (e.g., bulk docblocks)—show preview.
- ASK target audience level and preferred style.

## Required Confirmations

- Ask before editing existing documentation in-place.
- Ask preferred documentation style (concise vs. detailed) and target audience (beginner, intermediate, expert).
- Ask whether to commit changes to the repository or just present patches/diffs.

## Validation Checklist (finalize only after all checks pass)

- [ ] All public APIs documented (functions/classes/methods)
- [ ] Parameters, returns, exceptions described where applicable
- [ ] Examples added for complex functionality
- [ ] Business rules/constraints explained (why)
- [ ] No redundant/obvious comments added
- [ ] README includes Overview, Installation, Usage, API Reference, Contributing, License
- [ ] OpenAPI uses reusable `components`/`$ref` where appropriate
- [ ] CHANGELOG grouped by version/categorized
- [ ] Documentation matches actual code behavior
- [ ] Legible/concise/informative (active voice, <25 words/sentence, target audience)
- [ ] Accurate—no outdated info, working links

## References

See bundled references in `references/` for detailed domain-specific guidance: `api-documenter.md`, `changelog-generator.md`, `docblock-writer.md`, `readme-writer.md`.
