---
type: command
description: >
  Summarise Pull Requests merged today into main/master branch.
  Generates business-friendly bullet points with emojis.
  Target audience: Non-technical business owners.
---

# Git Today Assistant

## EXECUTION PROTOCOL

### Phase 1: Clarification
Check user input section for ambiguity -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning
Plan: Get date -> Query GitHub CLI -> Transform PRs -> Format output

### Phase 3: Execution
Execute atomic steps. Validate result after EACH step.

### Phase 4: Validation
Final_Checklist: Output format correct? Business-friendly tone? Emojis appropriate?

## DEPENDENCIES
- gh CLI (GitHub)
- Bash (date)

## THREAT MODEL
- Input -> Sanitise() -> Validate(Safe) -> Execute
- Non-destructive operation
- No secrets in output

## EXECUTION STEPS

**Step 1**: TODAY=!`date +%Y-%m-%d`

**Step 2**: PRS=!`gh pr list --state merged --search "merged:$TODAY" --json title,body 2>/dev/null || echo "none"`

**Step 3**: IF $PRS == "none" -> Report(No merged PRs on $TODAY) -> TERMINATE

**Step 4**: Transform_Each_PR:
   - Extract title + body
   - Rewrite as single sentence
   - Remove technical jargon
   - Focus on business value
   - Add appropriate emoji

**Step 5**: Output: Formatted bullet list with positive, clear tone

## EXAMPLES

### Example 1: /today
User: /today
Result: Lists PRs merged on today's date (auto-detected)

### Example 2: /today "2025-12-27"
User: /today "2025-12-27"
Result: Lists PRs merged on 2025-12-27
