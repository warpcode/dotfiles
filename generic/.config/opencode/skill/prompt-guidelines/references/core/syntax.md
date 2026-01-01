# SYNTAX & FORMATTING

## PURPOSE
Define STM (Structured Telegraphic Markdown) format for token-efficient documentation.

## STRUCTURED TELEGRAPHIC MARKDOWN (STM)
- **Rule**: Content == Keywords + Logic. Remove conversational filler.
- **Constraint**: Clarity > Brevity. Ambiguity == FALSE.

## LOGIC NOTATION
### Symbols
- `->` (Causes)
- `=>` (Implies)
- `!=` (Not)
- `&&` (AND)
- `||` (OR)

### Conditionals
- **Single**: IF condition THEN ... END
- **Two branches**: IF condition THEN ... ELSE ... END
- **Multiple**: IF condition THEN ... ELSE IF condition THEN ... ELSE ... END
- **Nested**: IF inside another IF block

### Line Breaks
- Each logic chain MUST be on new line
- Inside IF blocks: Indented lines, no bullet points
- Outside IF blocks: Each chain on new line
- Multi-line actions: Indent continuation lines

## VARIABLE BINDING
### Mode A (Structured)
- Enforce strict schema (JSON/YAML)
- "Keys == Immutable."

### Mode B (Conversational)
- Enforce Tone/Style
- "Explanation == Concise && Technical."

### Constraint
- Define Output_Mode explicitly

## DESCRIPTION FORMAT

### Skills
```yaml
description: >-
  [One-line purpose]
  Scope: [key capabilities]
  Excludes: [exclusions - domain skills only]
  Triggers: [keywords for routing]
```
- **Purpose**: One-sentence goal
- **Scope**: Key capabilities (no redundancy)
- **Excludes**: Domain skills only - topics NOT skill names (e.g., "database design", not "use database-engineering")
- **Triggers**: Keywords for routing
- **Token efficiency**: < 350 chars typical (1024 max)
- **Formatting**: Single newlines only, no blank lines
- **STM format**: Keywords only, no conversational filler

### Agents
```yaml
description: >-
  [One-line purpose]
  Scope: [key areas]
```
- **Purpose**: One sentence explaining what agent does
- **Scope**: Key areas covered (no redundancy)
- **Token efficiency**: < 250 chars preferred (1024 max)
- **Formatting**: Single newlines only, no blank lines
- **STM format**: Keywords only, no conversational filler

### Commands
```yaml
description: >-
  [One-line purpose]
  Scope: [areas covered]
```
- **Purpose**: One sentence explaining what command does
- **Scope**: Areas covered (no redundancy)
- **Token efficiency**: < 250 chars preferred (1024 max)
- **Formatting**: Single newlines only, no blank lines
- **STM format**: Keywords only, no conversational filler

## STM EXAMPLES

### Incorrect
```yaml
description: >-
  This agent is designed to help you with exploring the codebase and
  finding patterns. It can do things like searching for files,
  analyzing code structure, and understanding architecture.
```

### Correct
```yaml
description: >-
  General-purpose agent for code exploration and analysis.
  Scope: codebase search, pattern detection, file analysis, architecture understanding.
```

## REFERENCE LOADING
- **Syntax**: `Ref == @path/to/file`
- **Constraint**: Markdown Links `[text](path)` == FORBIDDEN
- **Rule**: All `@` paths MUST be relative to skill's main SKILL.md file
