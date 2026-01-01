# MODE DETECTION PROTOCOL

## PURPOSE
Define how to detect operational modes and apply behavioral frameworks.

## CORE PRINCIPLE
**Rule**: User Intent -> Mode Classify -> Load Behavioral Framework -> Switch ALL Dimensions

## DETECTION LOGIC
1. **Keyword Analysis**: Scan user input for mode keywords
2. **Intent Classification**: Match keywords to mode purpose (information, creation, review, planning, teaching)
3. **Behavioral Switch**: Once mode detected, apply ALL 7 dimensions (cognitive, workflow, validation, interaction, success, context, output) - NOT just output format
4. **Conditional Logic**: Use mode for behavior control (IF mode == review THEN read-only)
5. **Reference Loading**: Use mode to load appropriate reference files

## 5 OPERATIONAL MODES

### Mode 1: ANALYSE/READ
- **Intent**: Provide information, extract data, report findings
- **Keywords**: "what", "how", "explain", "analyze", "list", "show", "find"
- **Permissions**: Read-only (read, glob, grep)
- **Output Focus**: Clarity, hierarchy, quick scanning
- **Load**: @references/modes/analyse.md

### Mode 2: WRITE/EDIT/UPDATE
- **Intent**: Create, write, generate, update, edit, add content
- **Keywords**: "create", "write", "generate", "update", "edit", "add", "build"
- **Permissions**: Write/edit tools + User confirmation for destructive ops
- **Output Focus**: Changes, confirmation, before/after comparisons
- **Load**: @references/modes/write.md

### Mode 3: REVIEW/CHECK/VALIDATE
- **Intent**: Review, check, audit, validate, analyze for compliance
- **Keywords**: "review", "check", "audit", "validate", "compliance", "analyze issues"
- **Permissions**: Read-only (strictly enforced)
- **Output Focus**: Prioritized issues, severity classification
- **Load**: @references/modes/review.md

### Mode 4: PLAN/DESIGN
- **Intent**: Plan, design, structure, breakdown, estimate
- **Keywords**: "plan", "design", "structure", "breakdown", "estimate", "architecture"
- **Permissions**: Read-only (advisory only, no execution)
- **Output Focus**: Structured plans with objectives, dependencies, risk assessment
- **Load**: @references/modes/plan.md

### Mode 5: TEACH/EXPLAIN
- **Intent**: Teach, explain, guide, tutorial, learn
- **Keywords**: "teach", "explain", "guide", "tutorial", "learn", "how does X work"
- **Permissions**: Read-only
- **Output Focus**: Rationale, examples, best practices, anti-patterns
- **Load**: @references/modes/teach.md

## MULTI-MODE SUPPORT
- Prompts can activate multiple modes simultaneously
- Design output formats to combine modes when needed
- Maintain clarity when presenting multi-mode outputs
- Order modes logically (e.g., Analyse → Review → Plan → Write)
- **Load**: @references/modes/multi-mode.md

## BEHAVIORAL FRAMEWORK APPLICATION
Once mode detected, apply ALL 7 dimensions:
1. **Cognitive**: How to think about task
2. **Workflow**: How to execute steps
3. **Validation**: How to verify results
4. **Interaction**: How to engage user
5. **Success**: How to define completion
6. **Context**: How to manage information
7. **Output**: How to present results

## UNIVERSAL RULE
Applies to ALL operations (skills, agents, commands, prompts).
