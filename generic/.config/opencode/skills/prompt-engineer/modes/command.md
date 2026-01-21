# Mode: Command

## Purpose
Guidelines for creating quick-access, parameterized prompt templates that execute predefined workflows through slash commands in OpenCode and Claude Code.

## Blueprint Structure

### Core Principles

**Command = Prompt Template + Parameters + Context Assembly + Response Handler**

Commands are pre-configured prompts invoked via slash syntax (`/command-name args`) that combine static instructions with dynamic runtime parameters to execute focused workflows efficiently.

**Command vs Skill vs Agent**:

| Feature | Command | Skill | Agent |
|---------|---------|-------|-------|
| **Invocation** | `/command arg` | Auto-discovered | Conversational |
| **Complexity** | Simple, single-shot | Multi-step workflow | Delegated tasks |
| **Context** | Minimal, inline | Progressive disclosure | Full conversation |
| **Parameters** | Positional args | User provides | Clarifying questions |
| **Best For** | Repetitive templates | Tool-equipped processes | Complex reasoning |

### File Structure

**Option 1: Markdown Format (Recommended)**
```
.opencode/commands/command-name.md
~/.config/opencode/commands/command-name.md
```

**Option 2: JSON Config**
```
.opencode/config.json
~/.config/opencode/config.json
```

### Markdown Format Structure

```markdown
<!-- command-name.md -->

# Command: /command-name

## Description
[One-line description for command palette]

## Usage
/command-name [arg1] [arg2] [options]

## Parameters
- arg1: [Description, type, required/optional]
- arg2: [Description, type, required/optional]
- options: [Flag options: --verbose, --dry-run]

## Prompt Template
[Your prompt instructions with parameter placeholders]

Use $ARGUMENTS for all arguments as string.
Use $1, $2, $3 for positional arguments.
Use @filename to inject file contents.
Use *!command* to inject shell command output.

## Agent (optional)
[Agent name to execute this command]

## Temperature (optional)
[0.0-1.0]

## Response Handling
[Insert | Replace | Display | Save]
```

### JSON Config Structure

```json
{
  "commands": {
    "command-name": {
      "template": "Your prompt template with $ARGUMENTS and $1, $2 placeholders",
      "description": "One-line description for command palette",
      "agent": "agent-name",
      "temperature": 0.3,
      "responseHandling": "insert"
    }
  }
}
```

## Template Elements

### Parameter Placeholders

**$ARGUMENTS**
- All arguments combined as single string
- Use when treating arguments as free-form text
- Example: `/summarize $ARGUMENTS` where arguments are "this file focusing on security"

**$1, $2, $3, ...**
- Positional arguments
- Use when arguments have specific meanings
- Example: `/component $1 $2` where $1=component-name, $2=component-type

**@filename**
- Inject file contents into prompt
- Reads file and embeds content at that location
- Example: `Review this code: @src/components/Button.tsx`

**\*!shell-command\***
- Execute shell command and inject output
- Useful for dynamic context (git status, file listings)
- Example: `Analyze changed files: *!git diff --name-only*`

### Static vs Dynamic Content

**Static Content** (Cacheable):
```markdown
## Prompt Template

You are an expert React developer.

Create a new React component with the following requirements:
- Functional component with TypeScript
- PropTypes validation
- Comprehensive JSDoc documentation
- Unit tests with React Testing Library

DO NOT include:
- Class components
- PropTypes in JavaScript
- Inline styles
```

**Dynamic Content** (Runtime):
```markdown
Component name: $1
Component type: $2

[User-specific context: @current-file-path]
[Project conventions: @project-conventions.md]
```

**Best Practice**: Separate static instructions (cacheable) from dynamic parameters to enable prompt caching[76][79][141].

## Content Structure

### Required Sections

#### 1. Command Metadata
```markdown
# Command: /command-name

## Description
[Concise, action-oriented description visible in command palette]

## Usage
/command-name [required-arg] [optional-arg]

## Examples
/command-name Button functional
/command-name Modal --with-animation
```

#### 2. Parameter Specification
```markdown
## Parameters

### Required
- **arg1** (string): [Description, purpose, valid values]
- **arg2** (enum): [Description, options: value1 | value2 | value3]

### Optional
- **--flag** (boolean): [Description, default behavior without flag]
- **--option=value** (string): [Description, default value]

### Parameter Validation
- arg1: Must be PascalCase, alphanumeric only
- arg2: Must be one of: functional, class, hook
- --option: Must match pattern: [a-z-]+
```

#### 3. Prompt Template (Core Logic)
```markdown
## Prompt Template

### Context Setup
[Role assignment, expertise level]

### Task Definition
Your task is to [CLEAR ACTION] using the following parameters:
- Parameter 1: $1
- Parameter 2: $2
- All arguments: $ARGUMENTS

### Instructions
[Step-by-step directive instructions]

DO NOT:
- [Anti-pattern 1]
- [Anti-pattern 2]

### Output Format
[Structure, style, format requirements]

### Boilerplate (if applicable)
[Static code/text that should NOT be generated]
```

**Best Practices for Prompt Templates**:
- Use negative constraints: "DO NOT include..." (clear boundaries)[76][141]
- Separate boilerplate from generated content
- Be explicit about output format
- Use imperative language: "Create", "Generate", "Analyze"
- Keep instructions concise and directive

#### 4. Response Handling Strategy
```markdown
## Response Handling

### Default Behavior
[Insert | Replace | Display | Save to file]

### Insert Mode
- Location: [After selection | At cursor | End of file]
- Formatting: [Preserve indentation | Add spacing | Include markers]

### Replace Mode
- Target: [Current selection | Entire file | Specific pattern]
- Backup: [Create backup | Confirm before replace]

### Display Mode
- Format: [Code block | Plain text | Formatted markdown]
- Copy to clipboard: [Yes | No]

### Save Mode
- File path: [Pattern with $1, $2 substitution]
- Overwrite policy: [Ask | Overwrite | Append | Error]
```

### Optional Sections

#### Configuration
```markdown
## Configuration

### Agent Selection
**Agent**: code-generator
**Rationale**: Specialized in component scaffolding, understands project conventions

### Model Parameters
**Temperature**: 0.2 (deterministic, consistent structure)
**Max Tokens**: 2000 (sufficient for component + tests + docs)

### Tool Permissions (if agent used)
- Read: project-conventions.md, tsconfig.json
- Write: src/components/$1.tsx, src/components/$1.test.tsx
```

#### Validation & Error Handling
```markdown
## Validation

### Pre-Execution Checks
- [ ] Component name ($1) is valid PascalCase
- [ ] Component type ($2) is in allowed list
- [ ] Target directory exists: src/components/
- [ ] No naming conflicts: Check if src/components/$1.tsx exists

### Error Messages
**Error: Invalid component name**
```
Component name must be PascalCase (e.g., Button, UserProfile, DataTable).
Provided: $1
```

**Error: Component already exists**
```
Component $1 already exists at src/components/$1.tsx
Use --overwrite flag to replace, or choose different name.
```

### Post-Execution Verification
- Generated file is valid TypeScript (compile check)
- All imports resolve correctly
- Tests exist and are runnable
```

#### Examples with Full Context
```markdown
## Examples

### Example 1: Functional Component
**Command**: `/component Button functional`

**Context**:
- Project uses TypeScript, React 18, Material-UI
- Conventions: Functional components, named exports, JSDoc required

**Generated Output**:
```typescript
/**
 * Button component - Material-UI styled button with variant support
 * @param {ButtonProps} props - Component props
 */
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'text';
  onClick?: () => void;
  children: React.ReactNode;
}

export function Button({ variant = 'primary', onClick, children }: ButtonProps) {
  return (
    <MUIButton variant={variant} onClick={onClick}>
      {children}
    </MUIButton>
  );
}
```

**Response Handling**: Insert at src/components/Button.tsx

### Example 2: Component with Tests
**Command**: `/component Modal functional --with-tests`

**Execution**:
1. Generate component: src/components/Modal.tsx
2. Generate tests: src/components/Modal.test.tsx
3. Update index: src/components/index.ts

**Verification**:
- TypeScript compiles without errors
- Tests pass: `npm test Modal.test.tsx`
```

## Command Patterns

### Pattern 1: Code Generator
```markdown
# Command: /component

## Prompt Template
Create a new React component named $1 with TypeScript.

Component type: $2 (functional | class)

Requirements:
- Full TypeScript typing (Props interface, generic types)
- Comprehensive JSDoc documentation
- PropTypes validation (runtime checks)

DO NOT include:
- Inline styles (use styled-components or CSS modules)
- 'any' types (use proper typing)
- Console.log statements

Output format:
```typescript
[Generated component code]
```

Response: Insert at src/components/$1.tsx
```

### Pattern 2: Code Refactor
```markdown
# Command: /refactor

## Prompt Template
Refactor the following code: @$1

Apply these transformations:
- Extract repeated logic into helper functions
- Replace var with const/let appropriately
- Add TypeScript types if missing
- Improve naming for clarity

Preserve:
- Original functionality (behavior must be identical)
- Existing tests (should still pass)
- Public API (no breaking changes)

DO NOT:
- Change logic or algorithms
- Remove comments
- Reformat unless necessary for readability

Response: Replace current selection
```

### Pattern 3: Code Analysis
```markdown
# Command: /review

## Prompt Template
Perform code review on: @$1

Focus areas:
- Security vulnerabilities (injection, XSS, auth issues)
- Performance issues (O(n²), unnecessary re-renders, memory leaks)
- Maintainability (naming, complexity, coupling)

Output format:
## Issues Found
### Critical (security, correctness)
[List with severity, location, recommendation]

### Important (performance, maintainability)
[List with impact, suggestion]

### Suggestions (style, best practices)
[List with rationale]

Response: Display (do not modify files)
```

### Pattern 4: Documentation Generator
```markdown
# Command: /docs

## Prompt Template
Generate documentation for: @$1

Documentation should include:
- Purpose and overview
- Usage examples (2-3 realistic scenarios)
- API reference (functions, parameters, return types)
- Edge cases and error handling

Style: Technical documentation for developers

DO NOT:
- Include implementation details (focus on interface)
- Use vague language (be specific and concrete)
- Generate placeholder text

Response: Insert at docs/$1.md
```

### Pattern 5: Test Generator
```markdown
# Command: /test

## Prompt Template
Generate unit tests for: @$1

Test framework: Jest + React Testing Library
Coverage target: All public methods, edge cases, error scenarios

Test structure:
- describe: Component/function name
- it: Specific behavior being tested
- Arrange-Act-Assert pattern

DO NOT:
- Test implementation details (test behavior, not internals)
- Use snapshot tests (use explicit assertions)
- Include console.log or commented code

Response: Insert at $1.test.tsx (derived from $1 filename)
```

### Pattern 6: Shell Command Execution
```markdown
# Command: /analyze-changes

## Prompt Template
Analyze the following changes in the current Git branch:

Changed files: *!git diff --name-only main*

Diff summary:
*!git diff main --stat*

Provide:
1. Summary of changes (high-level overview)
2. Potential issues (breaking changes, missing tests)
3. Deployment considerations (migrations, config changes)

Response: Display
```

### Pattern 7: File Content Injection
```markdown
# Command: /similar-to

## Prompt Template
Generate code similar in style to: @$1

Analyze the reference file for:
- Code structure and organization patterns
- Naming conventions
- Comment style and documentation level
- Error handling approach

Create new code for: $2

Match the style and patterns from reference file while implementing the new requirements.

Response: Insert at appropriate location
```

## Validation Checklist

- [ ] **Command Name**: Lowercase, hyphenated, descriptive?
- [ ] **Description**: Concise, action-oriented, clear purpose?
- [ ] **Parameters**: All parameters documented with types?
- [ ] **Placeholders**: Correct use of $ARGUMENTS, $1, $2, @file, *!command*?
- [ ] **Instructions**: Clear, directive, negative constraints included?
- [ ] **Response Handling**: Specified (insert/replace/display/save)?
- [ ] **Examples**: At least 1-2 complete usage examples?
- [ ] **Validation**: Pre-execution checks for common errors?
- [ ] **Boilerplate**: Static content separated from dynamic?
- [ ] **Token Efficiency**: Static instructions cacheable?

## Common Pitfalls to Avoid

❌ **Vague Instructions**: "Make the code better"  
✅ **Directive**: "Refactor: Extract repeated logic into helpers, add types, improve naming"

❌ **No Negative Constraints**: Unclear what NOT to do  
✅ **Explicit Boundaries**: "DO NOT include: class components, any types, console.log"

❌ **Unclear Parameters**: $ARGUMENTS used for structured data  
✅ **Positional Args**: $1=name, $2=type for specific meanings

❌ **No Response Handling**: Unclear what happens with output  
✅ **Explicit**: "Insert at src/components/$1.tsx"

❌ **Mixed Static/Dynamic**: Hard to cache, inefficient  
✅ **Separated**: Static template + dynamic parameters

❌ **Missing Examples**: Users don't know how to use  
✅ **Concrete Scenarios**: Show 2-3 real invocations with context

❌ **No Validation**: Bad inputs cause confusing errors  
✅ **Pre-Checks**: Validate args, check file existence, format checking

## Platform-Specific Notes

### OpenCode Commands
- Location: `.opencode/commands/` or `~/.config/opencode/commands/`
- Format: Markdown (.md) preferred, JSON config supported
- Invocation: `/command-name args` in chat[141][146]
- Caching: Supported for static prompt portions[79]

### Claude Code Commands
- Location: Similar structure to OpenCode
- Format: Markdown with frontmatter
- Invocation: `/command-name args`
- Check current documentation for specifics

### Slash Command Best Practices
- **Name**: Verb-based, clear intent (`/generate`, `/analyze`, `/refactor`)
- **Discovery**: Descriptive names aid command palette search
- **Frequency**: Create commands for repetitive tasks (used 3+ times/week)
- **Simplicity**: Keep commands focused (single responsibility)
- **Composition**: Chain commands in sequence for complex workflows

## Example: Complete Command

```markdown
<!-- component-generator.md -->

# Command: /component

## Description
Generate React TypeScript component with props, tests, and documentation

## Usage
/component [ComponentName] [functional|class] [options]

## Parameters

### Required
- **ComponentName** (string): PascalCase component name (e.g., Button, UserProfile)
- **type** (enum): Component type - `functional` | `class`

### Optional
- **--with-tests** (boolean): Generate unit test file
- **--with-story** (boolean): Generate Storybook story
- **--material-ui** (boolean): Use Material-UI components

## Prompt Template

### Context
You are an expert React developer specializing in TypeScript and component architecture.

### Task
Create a new React component with the following specifications:

**Component Name**: $1  
**Component Type**: $2  
**Project Context**: @project-conventions.md

### Requirements

#### Code Structure
- Functional component with TypeScript (if type=functional)
- Full TypeScript typing: Props interface, generic types where appropriate
- Named export: `export function ComponentName({ props }: ComponentNameProps)`
- Comprehensive JSDoc documentation above component and complex functions

#### PropTypes
- Define Props interface with all properties
- Use TypeScript union types for variants/enums
- Mark optional props with `?` or provide defaults
- Include JSDoc comments on each prop

#### Error Handling
- Validate props in development mode
- Provide meaningful error messages for invalid props
- Handle edge cases (null, undefined, empty arrays)

#### DO NOT Include
- Class components (unless $2=class explicitly requested)
- Any types (use proper TypeScript typing)
- Inline styles (use styled-components or CSS modules per project conventions)
- Console.log or debug statements
- if __name__ == "__main__" or similar test code

### Output Format

```typescript
/**
 * [Component description - purpose and usage]
 * @param {ComponentNameProps} props - Component properties
 * @example
 * ```tsx
 * <ComponentName prop1="value" prop2={true} />
 * ```
 */
interface ComponentNameProps {
  /** [Prop description] */
  prop1: string;
  /** [Prop description] */
  prop2?: boolean;
}

export function ComponentName({ prop1, prop2 = false }: ComponentNameProps) {
  // Component logic
  return (
    <div>
      {/* Component JSX */}
    </div>
  );
}
```

### Boilerplate
DO NOT generate these imports (already in project template):
```typescript
import React from 'react';
import { styled } from '@mui/material/styles';
```

## Response Handling

### Default Behavior
Insert generated component at: `src/components/$1.tsx`

### With --with-tests Flag
1. Generate component: `src/components/$1.tsx`
2. Generate test: `src/components/$1.test.tsx`

### With --with-story Flag
1. Generate component: `src/components/$1.tsx`
2. Generate story: `src/components/$1.stories.tsx`

### Verification
After generation, verify:
- File created successfully
- TypeScript compiles: `tsc --noEmit src/components/$1.tsx`
- No linting errors: `eslint src/components/$1.tsx`

## Configuration

### Agent Selection
**Agent**: code-generator
**Rationale**: Specialized in component scaffolding with project convention awareness

### Model Parameters
**Temperature**: 0.2 (deterministic, consistent structure)

### Tool Permissions
- Read: project-conventions.md, tsconfig.json, .eslintrc.js
- Write: src/components/*.tsx, src/components/*.test.tsx

## Validation

### Pre-Execution Checks
1. Validate $1 is PascalCase: `^[A-Z][a-zA-Z0-9]*$`
2. Validate $2 is in: `functional`, `class`
3. Check target directory exists: `src/components/`
4. Check no conflict: `!exists(src/components/$1.tsx)` or --overwrite flag present

### Error Messages

**Error: Invalid component name**
```
Component name must be PascalCase (e.g., Button, UserProfile, DataTable).
Provided: $1

Valid examples:
- /component Button functional
- /component UserProfile functional --with-tests
```

**Error: Component already exists**
```
Component $1 already exists at src/components/$1.tsx

Options:
1. Choose different name: /component ${1}V2 functional
2. Overwrite existing: /component $1 functional --overwrite
3. View existing: cat src/components/$1.tsx
```

**Error: Invalid component type**
```
Component type must be: functional | class
Provided: $2

Use: /component $1 functional
```

## Examples

### Example 1: Simple Button Component
**Command**: `/component Button functional`

**Generated**: `src/components/Button.tsx`
```typescript
/**
 * Button component - Material-UI styled button with variant support
 * @param {ButtonProps} props - Component properties
 * @example
 * ```tsx
 * <Button variant="primary" onClick={handleClick}>
 *   Click Me
 * </Button>
 * ```
 */
interface ButtonProps {
  /** Button variant style */
  variant?: 'primary' | 'secondary' | 'text';
  /** Click handler */
  onClick?: () => void;
  /** Button content */
  children: React.ReactNode;
  /** Disabled state */
  disabled?: boolean;
}

export function Button({ 
  variant = 'primary', 
  onClick, 
  children,
  disabled = false 
}: ButtonProps) {
  return (
    <MUIButton 
      variant={variant} 
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </MUIButton>
  );
}
```

### Example 2: Component with Tests
**Command**: `/component Modal functional --with-tests`

**Generated Files**:
1. `src/components/Modal.tsx` (component)
2. `src/components/Modal.test.tsx` (tests)

**Test File**:
```typescript
import { render, screen } from '@testing-library/react';
import { Modal } from './Modal';

describe('Modal', () => {
  it('renders children when open', () => {
    render(<Modal open={true}>Test Content</Modal>);
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('does not render when closed', () => {
    render(<Modal open={false}>Test Content</Modal>);
    expect(screen.queryByText('Test Content')).not.toBeInTheDocument();
  });

  it('calls onClose when backdrop clicked', async () => {
    const handleClose = jest.fn();
    render(<Modal open={true} onClose={handleClose}>Content</Modal>);
    
    const backdrop = screen.getByTestId('modal-backdrop');
    backdrop.click();
    
    expect(handleClose).toHaveBeenCalledTimes(1);
  });
});
```

### Example 3: Using File Context
**Command**: `/component UserCard functional` (with @project-conventions.md)

**Project Conventions** (injected):
```markdown
# Project Conventions
- Use styled-components for styling
- Export components as named exports
- Include PropTypes for runtime validation
- Use React.FC type for functional components
```

**Generated** (follows conventions):
```typescript
import styled from 'styled-components';

const Card = styled.div`
  padding: 1rem;
  border: 1px solid #ccc;
  border-radius: 4px;
`;

interface UserCardProps {
  name: string;
  email: string;
  avatar?: string;
}

export const UserCard: React.FC<UserCardProps> = ({ name, email, avatar }) => {
  return (
    <Card>
      {avatar && <img src={avatar} alt={name} />}
      <h3>{name}</h3>
      <p>{email}</p>
    </Card>
  );
};
```

## Token Optimization

### ✅ Safe to Optimize
- Remove duplicate instructions across similar commands
- Use references: "Follow project conventions @project-conventions.md"
- Cache static boilerplate separately
- Reduce example count if pattern clear

### ❌ Never Optimize Away
- Negative constraints (DO NOT...)
- Parameter specifications
- Response handling instructions
- Validation rules
- Error messages

## References

This mode incorporates best practices from:
- OpenCode commands documentation[141][146]
- Command palette patterns[76][149]
- Prompt caching strategies[79]
- Aider command-line patterns[79]
- VS Code extension command structure[76]
