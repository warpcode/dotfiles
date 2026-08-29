# Skill Audit & Improvement SOP

Standard Operating Procedure for auditing triggering reliability, structural health, and prompt performance across skill packages.

---

## Audit Execution Steps

1. **Structural Validation**: Execute `python3 scripts/validate.py <skill-path>` to catch syntax, frontmatter, and missing resource errors.
2. **Triggering Review**:
   - Inspect frontmatter `description` for literal user trigger phrases.
   - Verify length is under 1024 characters.
   - Address undertriggering or overtriggering using evaluation protocols in `@references/evals.md`.
3. **Progressive Disclosure Audit**:
   - Verify `SKILL.md` body is concise (<500 lines, target ~60-80 lines).
   - Ensure deep domain knowledge is deferred to `@references/`.
   - Verify helper scripts in `scripts/` follow `@references/script-standards.md`.
4. **Generalization Check**:
   - Eliminate hardcoded paths or over-fitting to single chat examples.
   - Replace MUST-stacking with clear operational rationales and boundaries.

---

## Audit Report Contract

When performing a formal skill audit, structure findings using this exact format:

```markdown
# [Skill Name] Audit Report

## 1. Trigger Check
- **Description Quality**: [Evaluation of keywords, length, and trigger phrases]
- **Routing Reliability**: [Assessment of undertrigger / overtrigger risks]

## 2. Structure & Compliance Findings
- **Frontmatter & Layout**: [PASS/FAIL against standard]
- **Progressive Disclosure**: [Context budget and reference offloading analysis]
- **Script Hygiene**: [Verification of `--help`, compilation, and zero-deps]

## 3. Recommended Actions
1. [Action item 1]
2. [Action item 2]
```

