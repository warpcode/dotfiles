# Skill Validation and Testing

## Validation and Testing

### Validate the Skill

Check these requirements:

✅ **File structure**:
- [ ] SKILL.md exists in correct location
- [ ] Directory name matches frontmatter `name`

✅ **YAML frontmatter**:
- [ ] Opening `---` on line 1
- [ ] Closing `---` before content
- [ ] Valid YAML (no tabs, correct indentation)
- [ ] `name` follows naming rules
- [ ] `description` is specific and < 1024 chars

✅ **Content quality**:
- [ ] Clear instructions for Claude
- [ ] Concrete examples provided
- [ ] Edge cases handled
- [ ] Dependencies listed (if any)

✅ **Testing**:
- [ ] Description matches user questions
- [ ] Skill activates on relevant queries
- [ ] Instructions are clear and actionable

### Test the Skill

1. **Restart your AI assistant** (Claude Code or opencode if running) to load the Skill

2. **Ask relevant questions** that match the description:
   ```
   Can you help me extract text from this PDF?
   ```

3. **Verify activation**: Claude should use the Skill automatically

4. **Check behavior**: Confirm Claude follows the instructions correctly

### Debug if needed

If Claude doesn't use the Skill:

1. **Make description more specific**:
   - Add trigger words
   - Include file types
   - Mention common user phrases

2. **Check file location**:
   ```bash
   # Claude Code
   ls ~/.claude/skills/skill-name/SKILL.md
   ls .claude/skills/skill-name/SKILL.md

   # opencode
   ls ~/.config/opencode/skills/skill-name/SKILL.md
   ls .opencode/skills/skill-name/SKILL.md
   ```

3. **Validate YAML**:
   ```bash
   cat SKILL.md | head -n 10
   ```

4. **Run debug mode**:
   ```bash
   claude --debug  # Claude Code
   opencode --debug  # opencode
   ```

## Common patterns

### Read-only Skill

```yaml
---
name: code-reader
description: Read and analyze code without making changes. Use for code review, understanding codebases, or documentation.
allowed-tools: Read, Grep, Glob
---
```

### Script-based Skill

```yaml
---
name: data-processor
description: Process CSV and JSON data files with Python scripts. Use when analyzing data files or transforming datasets.
---

# Data Processor

## Instructions

1. Use the processing script:
```bash
python scripts/process.py input.csv --output results.json
```

2. Validate output with:
```bash
python scripts/validate.py results.json
```
```

### Multi-file Skill with progressive disclosure

```yaml
---
name: api-designer
description: Design REST APIs following best practices. Use when creating API endpoints, designing routes, or planning API architecture.
---

# API Designer

Quick start: See [examples.md](examples.md)

Detailed reference: See [reference.md](reference.md)

## Instructions

1. Gather requirements
2. Design endpoints (see examples.md)
3. Document with OpenAPI spec
4. Review against best practices (see reference.md)
```

## Best practices for Skill authors

1. **One Skill, one purpose**: Don't create mega-Skills
2. **Specific descriptions**: Include trigger words users will say
3. **Clear instructions**: Write for Claude, not humans
4. **Concrete examples**: Show real code, not pseudocode
5. **List dependencies**: Mention required packages in description
6. **Test with teammates**: Verify activation and clarity
7. **Version your Skills**: Document changes in content
8. **Use progressive disclosure**: Put advanced details in separate files
9. **Be concise**: The context window is a public good. Skills share the context window with everything else Claude needs: system prompt, conversation history, other Skills' metadata, and the actual user request. Default assumption: Claude is already very smart. Only add context Claude doesn't already have. Challenge each piece of information: "Does Claude really need this explanation?" and "Does this paragraph justify its token cost?" Prefer concise examples over verbose explanations.
10. **Set appropriate degrees of freedom**: Match the level of specificity to the task's fragility and variability. High freedom (text-based instructions): Use when multiple approaches are valid, decisions depend on context, or heuristics guide the approach. Medium freedom (pseudocode or scripts with parameters): Use when a preferred pattern exists, some variation is acceptable, or configuration affects behavior. Low freedom (specific scripts, few parameters): Use when operations are fragile and error-prone, consistency is critical, or a specific sequence must be followed. Think of Claude as exploring a path: a narrow bridge with cliffs needs specific guardrails (low freedom), while an open field allows many routes (high freedom).

## Validation checklist

Before finalizing a Skill, verify:

- [ ] Name is lowercase, hyphens only, max 64 chars
- [ ] Description is specific and < 1024 chars
- [ ] Description includes "what" and "when"
- [ ] YAML frontmatter is valid
- [ ] Instructions are step-by-step
- [ ] Examples are concrete and realistic
- [ ] Dependencies are documented
- [ ] File paths use forward slashes
- [ ] Skill activates on relevant queries
- [ ] Claude follows instructions correctly

## Troubleshooting

**Skill doesn't activate**:
- Make description more specific with trigger words
- Include file types and operations in description
- Add "Use when..." clause with user phrases

**Multiple Skills conflict**:
- Make descriptions more distinct
- Use different trigger words
- Narrow the scope of each Skill

**Skill has errors**:
- Check YAML syntax (no tabs, proper indentation)
- Verify file paths (use forward slashes)
- Ensure scripts have execute permissions
- List all dependencies

## Examples

See the documentation for complete examples:
- Simple single-file Skill (commit-helper)
- Skill with tool permissions (code-reviewer)
- Multi-file Skill (pdf-processing)

## Output format

When creating a Skill, I will:

1. Ask clarifying questions about scope and requirements
2. Suggest a Skill name and location
3. Create the SKILL.md file with proper frontmatter
4. Include clear instructions and examples
5. Add supporting files if needed
6. Provide testing instructions
7. Validate against all requirements

The result will be a complete, working Skill that follows all best practices and validation rules for Claude Code and opencode.