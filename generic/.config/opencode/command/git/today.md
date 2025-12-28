---
description: >-
  Summarise Pull Requests merged today into main/master branch.
  Generates business-friendly bullet points with emojis.
  Target audience: Non-technical business owners.
---

<rules>
## Phase 1: Clarification (Ask)
IF $ARGUMENTS.ambiguous != FALSE -> List(Questions) -> Wait(User_Input)

## Phase 2: Planning (Think)
Plan: Get date -> Query GitHub CLI -> Transform PRs -> Format output

## Phase 3: Execution (Do)
Execute atomic steps. Validate result after EACH step.

## Phase 4: Validation (Check)
Final_Checklist: Output format correct? Business-friendly tone? Emojis appropriate?
</rules>

<context>
**Dependencies**: gh CLI (GitHub), Bash (date)

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(Safe) -> Execute
- Non-destructive operation
- No secrets in output

**Transform Rules**:
- Single sentence per PR
- Plain English (no jargon)
- Business benefit focus
  - Add relevant emoji: 🚀 Feature, 🐛 Fix, ⚡ Optimisation, 🔒 Security, 📚 Docs, ♻️ Refactor
</context>

<user>
    <default>
        Today's date (auto-generated)
    </default>
    <input>
        $ARGUMENTS
    </input>
</user>

<execution>
**Step 1**: TODAY=!`date +%Y-%m-%d`

**Step 2**: PRS=!`gh pr list --state merged --search "merged:$TODAY" --json title,body 2>/dev/null || echo "none"`

**Step 3**: IF $PRS == "none" -> Report(No merged PRs on $TODAY) -> EXIT

**Step 4**: Transform_Each_PR:
  - Extract title + body
  - Rewrite as single sentence
  - Remove technical jargon
  - Focus on business value
  - Add appropriate emoji

**Step 5**: Output: Formatted bullet list with positive, clear tone
</execution>

<examples>
<example>
User: /today
Result: Lists PRs merged on today's date (auto-detected)
</example>

<example>
User: /today "2025-12-27"
Result: Lists PRs merged on 2025-12-27
</example>
</examples>
