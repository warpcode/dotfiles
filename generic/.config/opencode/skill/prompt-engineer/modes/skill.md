# Mode: Skill

## Purpose
Guidelines for creating discoverable, reusable, tool-equipped instruction sets that extend AI assistant capabilities in OpenCode and Claude Code through lazy-loaded, context-aware execution patterns.

## Blueprint Structure

### Core Principles

**Skill = Discovery + Instructions [+ Tools] [+ Resources]**

Skills are discovered by AI based on description keywords and invoked on-demand. While simple skills may only contain instructions, advanced skills leverage specified tool permissions and reference bundled resources via lazy-loading to maintain a minimal initial context.

**Progressive Disclosure**:
1. Metadata (name + description) → Loaded at startup for discovery
2. Full SKILL.md prompt → Loaded when skill invoked
3. References/scripts → Loaded on-demand during execution

### File Structure

```
skill-name/
├── SKILL.md          # Required: ALL CAPS, main prompt
├── LICENSE.txt       # Optional: license file
├── scripts/          # Optional: executable Python/Bash (not loaded into context)
│   ├── process.py
│   └── analyze.sh
├── references/       # Optional: documentation loaded via Read tool
│   ├── api-docs.md
│   └── examples/
└── assets/           # Optional: templates/binaries (referenced by path only)
    └── template.json
```

**Key Principle**: Only SKILL.md frontmatter loaded initially. Full content + resources lazy-loaded on invocation[131][134][137].

### Required: Frontmatter (YAML)

```yaml
---
name: skill-name                    # Required
description: "Brief description"     # Required (max 1024 chars)
license: LICENSE.txt                 # Optional
allowed-tools: "Read,Write"          # Optional: comma-separated
model: "claude-sonnet-4"             # Optional: override or "inherit"
version: "1.0.0"                     # Optional
context: fork                        # Optional: fork | append
agent: general-purpose               # Optional: when context:fork
user-invocable: true                 # Optional: default true
disable-model-invocation: false      # Optional: block Skill tool
mode: false                          # Optional: categorize as mode
---
```

#### Frontmatter Field Specifications

**name** (required)
- Format: `lowercase-hyphenated`, alphanumeric + single hyphens
- Max length: 64 characters
- Examples: `pdf-extractor`, `api-documentation-generator`, `test-coverage-analyzer`
- Avoid: `PdfExtractor`, `pdf__extractor`, `pdf-extractor-tool-v2`

**description** (required)
- Max length: 1024 characters
- **PRIMARY DISCOVERY SIGNAL**: AI uses this to determine relevance[1][8][131]
- Include natural keywords users would say: "Use when...", "This skill should be used when..."
- Action-oriented: "Extract text and tables from PDF files"
- Be specific about capabilities: "Analyze TypeScript codebases for test coverage gaps and generate missing unit tests"

**allowed-tools** (optional, critical for security)
- Comma-separated list of tools (no spaces around commas)
- Use wildcards for specific commands: `Bash(python {baseDir}/scripts/*:*)`
- **Principle of least privilege**: ONLY tools actually needed[1][131][134]
- Common patterns:
  ```yaml
  # Script automation
  allowed-tools: "Bash(python {baseDir}/scripts/*:*),Read,Write"
  
  # Read-process-write
  allowed-tools: "Read,Write"
  
  # Search and analyze
  allowed-tools: "Grep,Read"
  
  # Git operations
  allowed-tools: "Bash(git status:*),Bash(git diff:*),Read"
  
  # Command chaining
  allowed-tools: "Bash(npm install:*),Bash(npm run:*),Read"
  ```

**model** (optional)
- Specific model: `claude-sonnet-4`, `claude-opus-4`
- Inherit from context: `inherit`
- Use when skill needs specific model capabilities[131]

**context** (optional, OpenCode-specific)
- `fork`: Run in isolated context (separate conversation thread)[1][134]
- `append`: Add to current conversation context (default)
- Use `fork` when: needs different tool access, separate execution, prevents main context pollution

**agent** (optional)
- Required when `context: fork`
- Specifies which agent runs forked skill[1][134]

**user-invocable** (optional)
- `true`: Visible in slash menu (default)[8][131]
- `false`: Only callable by other skills/agents

**disable-model-invocation** (optional)
- `true`: Block model from invoking this skill via Skill tool[131]
- `false`: Allow model invocation (default)
- Security: Use when skill should only be user-triggered

**mode** (optional)
- `true`: Categorize as mode command (like /chat, /code)[131]
- `false`: Regular skill (default)

### Standard Content Structure

```markdown
# [One-line Purpose Statement]

Use this skill to [SPECIFIC OUTCOME] when [TRIGGER CONDITION].

## Overview

**What**: [What this skill accomplishes]
**When**: [Situations where this skill should be used]
**Output**: [What user receives after execution]

## Prerequisites (Optional)

**Required Tools**: [Tools that must be in allowed-tools]
**Required Files**: [Files that must exist, file patterns]
**Required Context**: [Information user must provide]

## Instructions

### Step 1: [Imperative Action Verb]
[Concrete, actionable instruction]
[Tool usage: Read {baseDir}/references/file.md]
[Tool usage: Bash python {baseDir}/scripts/script.py arg1]

### Step 2: [Next Action]
[Concrete instruction]
[Decision logic: if X then Y, else Z]

### Step 3: [Final Action]
[Concrete instruction]
[Output formatting requirements]

## Output Format (Optional)

### Structure
[How results should be organized]

### Example Output
```[format]
[Complete example of expected output]
```

## Error Handling (Optional)
**Cause**: [What causes this error]
**Resolution**: [How to handle it]
**User Action**: [What user should do]

## Examples (Optional)

### Example 1: [Scenario Name]
**User Request**: [What user asked for]
**Context**: [Relevant files, state]
**Execution**: [What skill does step-by-step]
**Result**: [What user receives]

### Example 2: [Different Scenario]
...

## Resources (Optional)
- `{baseDir}/references/api-spec.md`: [Description]
- `{baseDir}/references/examples/`: [Description]

### External Tools
- Script: `{baseDir}/scripts/process.py`: [Purpose, arguments]
- Script: `{baseDir}/scripts/analyze.sh`: [Purpose, arguments]

### Templates
- `{baseDir}/assets/config.json`: [Purpose, how to use]
```

### Content Best Practices

#### Discovery Optimization (800-5000 words optimal content)
- **Description is king**: Most important factor for AI discovery[1][8][131]
- Include trigger terms in both description and overview
- Natural language: "Use this skill when you need to..." not "This skill does..."
- Keywords users would naturally say: "extract", "analyze", "generate", "refactor"
- Specify concrete use cases in description

#### Progressive Disclosure Pattern
```
Startup:
  Load: name, description, metadata (minimal context)

When Invoked:
  Load: Full SKILL.md content into context

During Execution:
  Load: references/ files via Read tool (on-demand)
  Execute: scripts/ via Bash tool (when called)
  Reference: assets/ by path (not loaded into context)
```

**Benefit**: Initial context minimal, full capability available when needed[131][137].

#### Tool Permission Patterns

**Bad (Too Permissive)**:
```yaml
allowed-tools: "Bash,Read,Write,Edit,Glob,Grep"  # ❌ Overly broad
```

**Good (Principle of Least Privilege)**:
```yaml
allowed-tools: "Bash(python {baseDir}/scripts/*:*),Read(workspace/**,{baseDir}/references/**)"  # ✅ Specific
```

**Tool Wildcard Syntax**:
- `Bash(command pattern:output_pattern)`
- `{baseDir}`: Skill root directory
- `*`: Wildcard matching
- Examples:
  ```yaml
  Bash(git status:*)           # Allow "git status", capture any output
  Bash(npm run:*)               # Allow "npm run" with any args
  Bash(python {baseDir}/*.py:*) # Allow Python scripts in skill dir
  Read(workspace/**)            # Read any file in workspace
  Write({baseDir}/output/*)     # Write to skill output dir only
  ```

#### {baseDir} Usage
- Always use `{baseDir}` for skill-relative paths
- Never hardcode absolute paths
- Enables skill portability and reuse[1][131][134]

**Examples**:
```bash
# In SKILL.md instructions
Read the API documentation from {baseDir}/references/api-spec.md

# In allowed-tools
Bash(python {baseDir}/scripts/analyze.py:*)

# In skill instructions
Execute: Bash python {baseDir}/scripts/process.py --input "$INPUT_FILE"
```

### Optional Sections

#### Decision Trees (for complex conditional logic)
```markdown
## Decision Logic

### Flowchart
```
User Request → Determine File Type
  ├─ PDF → Use {baseDir}/scripts/extract_pdf.py
  ├─ DOCX → Use {baseDir}/scripts/extract_docx.py
  └─ TXT → Direct Read tool

Extract Content → Parse Structure
  ├─ Has Tables → Extract to JSON
  └─ Plain Text → Extract to Markdown

Format Output → Return to User
```
```

#### Configuration Reference
```markdown
## Configuration

### Required Environment Variables
- `API_KEY`: [Purpose, where to obtain]
- `MODEL_NAME`: [Options, defaults]

### Optional Settings
Edit `{baseDir}/config.json`:
```json
{
  "timeout": 30,
  "max_retries": 3,
  "output_format": "markdown"
}
```
```

#### Testing Instructions
```markdown
## Testing This Skill

### Manual Test
1. Create test file: `test.pdf`
2. Invoke: `/skill-name test.pdf`
3. Verify output contains: [expected content]

### Automated Test
Run: `Bash python {baseDir}/scripts/test_skill.py`
Expected: All tests pass, no errors
```

## Validation Checklist

- [ ] **Frontmatter Complete**: name, description present and valid format?
- [ ] **Description Discovery**: Includes natural trigger keywords users would say?
- [ ] **Tool Permissions**: Only minimal necessary tools in allowed-tools?
- [ ] **{baseDir} Usage**: All skill-relative paths use {baseDir}?
- [ ] **Prerequisites Clear**: Required files, tools, context documented?
- [ ] **Instructions Actionable**: Each step is concrete and executable?
- [ ] **Output Format Defined**: Structure and examples provided?
- [ ] **Error Handling**: Documented with resolutions (if applicable)?
- [ ] **Examples Complete**: Real-world scenarios provided (recommended)?
- [ ] **Resources Documented**: Bundled files, scripts, templates listed (if applicable)?
- [ ] **Progressive Disclosure**: External references not embedded, loaded via Read (if applicable)?

## Common Pitfalls to Avoid

❌ **Vague Description**: "A skill for working with files"  
✅ **Specific**: "Extract text, tables, and images from PDF files and convert to Markdown format"

❌ **Overly Permissive Tools**: `allowed-tools: "Bash,Read,Write,Edit"`  
✅ **Least Privilege**: `allowed-tools: "Bash(python {baseDir}/scripts/extract.py:*),Read,Write"`

❌ **Hardcoded Paths**: `Read /Users/john/skills/my-skill/data.json`  
✅ **{baseDir}**: `Read {baseDir}/references/data.json`

❌ **Embedded Large Data**: Paste entire API docs into SKILL.md  
✅ **Progressive Loading**: Store in `references/`, load via `Read {baseDir}/references/api-docs.md`

❌ **Unclear Instructions**: "Process the files"  
✅ **Concrete Steps**: "1. Read {baseDir}/references/schema.json\n2. For each file in workspace matching *.ts:\n3. Execute Bash python {baseDir}/scripts/analyze.py $FILE"

❌ **No Error Handling**: Silent failures  
✅ **Explicit Errors**: "Error: File not found → Check {baseDir}/required-files/ → User action: Run setup script"

❌ **Generic Examples**: "User asks for help"  
✅ **Concrete Scenarios**: "User provides Git repo URL → Skill clones repo → Analyzes commit history → Generates report"

## Platform-Specific Notes

### Directory Locations
- **OpenCode**: `.opencode/skills/<name>/SKILL.md` or `~/.config/opencode/skills/<name>/SKILL.md`
- **Claude Code**: `.claude/skills/<name>/SKILL.md` or `~/.claude/skills/<name>/SKILL.md`
- **Cursor**: `.cursor/skills/<name>/SKILL.md` or `~/.cursor/skills/<name>/SKILL.md`
- **GitHub Copilot**: `.github/skills/<name>/SKILL.md` or `~/.copilot/skills/<name>/SKILL.md`

### OpenCode vs Claude Code Differences

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| **Context Modes** | `fork`, `append` | N/A (always append) |
| **Agent Assignment** | `agent:` field when `context:fork` | N/A |
| **Skill Discovery** | Automatic via description | Automatic via description |
| **Tool Restrictions** | `allowed-tools` with wildcards | `allowed-tools` simpler syntax |
| **{baseDir}** | Supported | Supported |

### Tool Availability by Platform

**OpenCode**: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `Skill` (invoke other skills)[1][146]

**Claude Code**: Similar tool set, check current documentation[8][131]

## Example: Complete Skill

```yaml
---
name: api-integration-generator
description: "Generate type-safe API client code from OpenAPI/Swagger specifications. Use when you need to create SDK code, client libraries, or typed API wrappers from API documentation."
allowed-tools: "Bash(python {baseDir}/scripts/generate.py:*),Read,Write"
model: inherit
version: "1.2.0"
user-invocable: true
---

# API Integration Generator

Use this skill to automatically generate type-safe API client code from OpenAPI 3.x or Swagger 2.x specifications.

## Overview

**What**: Generates production-ready API client code in TypeScript, Python, or Go from OpenAPI specs
**When**: You have an OpenAPI/Swagger specification and need client SDK code
**Output**: Complete API client with types, error handling, authentication, and usage examples

## Prerequisites

**Required Tools**: 
- `Bash(python {baseDir}/scripts/generate.py:*)`: Code generator script
- `Read`: To load OpenAPI spec and templates
- `Write`: To write generated code files

**Required Files**:
- OpenAPI 3.x or Swagger 2.x specification (JSON or YAML)

**Required Context**:
- Target programming language (TypeScript, Python, Go)
- Output directory path
- Optional: Authentication type (API key, OAuth2, Bearer)

## Instructions

### Step 1: Validate OpenAPI Specification
Read the provided OpenAPI specification file.
Verify it's valid OpenAPI 3.x or Swagger 2.x format.
If invalid, report specific validation errors and stop.

### Step 2: Load Language Templates
Based on target language, load appropriate templates:
- TypeScript: Read {baseDir}/templates/typescript/*
- Python: Read {baseDir}/templates/python/*
- Go: Read {baseDir}/templates/go/*

### Step 3: Generate Client Code
Execute code generator:
```bash
Bash python {baseDir}/scripts/generate.py \
  --spec "$SPEC_PATH" \
  --lang "$TARGET_LANG" \
  --output "$OUTPUT_DIR" \
  --auth "$AUTH_TYPE"
```

### Step 4: Write Generated Files
For each generated file from script output:
- Parse file path and content from generator output
- Write file to specified output directory
- Maintain directory structure

### Step 5: Create Usage Documentation
Generate README.md with:
- Installation instructions
- Authentication setup
- Basic usage examples
- API endpoint coverage summary

## Output Format

### File Structure
```
<output_dir>/
├── README.md           # Usage documentation
├── client.ts           # Main client class (or .py, .go)
├── types.ts            # Type definitions
├── errors.ts           # Error classes
├── auth.ts             # Authentication handlers
└── endpoints/          # Endpoint-specific modules
    ├── users.ts
    ├── posts.ts
    └── ...
```

### Example Generated Client (TypeScript)
```typescript
import { APIClient } from './client';

const client = new APIClient({
  baseURL: 'https://api.example.com',
  apiKey: process.env.API_KEY
});

// Type-safe API calls
const user = await client.users.getById(123);
const posts = await client.posts.list({ authorId: user.id });
```

## Error Handling

### Error: Invalid OpenAPI Specification
**Cause**: Spec file is malformed or unsupported version
**Resolution**: Validate spec against OpenAPI schema
**User Action**: Fix specification errors, ensure version is 3.0+ or 2.0

### Error: Unsupported Language
**Cause**: Target language not in [TypeScript, Python, Go]
**Resolution**: Check language parameter
**User Action**: Specify one of the supported languages

### Error: Generator Script Failed
**Cause**: Python script encountered error during generation
**Resolution**: Check script output for details
**User Action**: Review error message, ensure spec is valid, check dependencies

### Error: Write Permission Denied
**Cause**: Cannot write to output directory
**Resolution**: Verify directory exists and is writable
**User Action**: Create output directory or choose different path

## Examples

### Example 1: TypeScript Client from Petstore API
**User Request**: "Generate TypeScript client for this OpenAPI spec"
**Context**: User provides `petstore-openapi.yaml`
**Execution**:
1. Read and validate petstore-openapi.yaml
2. Load TypeScript templates from {baseDir}/templates/typescript/
3. Execute generator: `python generate.py --spec petstore-openapi.yaml --lang typescript --output ./src/api-client`
4. Write generated files: client.ts, types.ts, endpoints/*.ts
5. Create README.md with usage examples
**Result**: Complete TypeScript API client in ./src/api-client/ with types and documentation

### Example 2: Python Client with OAuth2
**User Request**: "Create Python SDK for our REST API with OAuth2 authentication"
**Context**: OpenAPI spec at workspace/specs/api-v2.json, OAuth2 flow required
**Execution**:
1. Read workspace/specs/api-v2.json
2. Validate OAuth2 security scheme in spec
3. Load Python templates with OAuth2 support
4. Generate client with OAuth2 handler
5. Include token refresh logic
**Result**: Python package with OAuth2 authentication, automatic token refresh, type hints

## Resources

### Bundled Templates
- `{baseDir}/templates/typescript/`: TypeScript code templates (client, types, auth)
- `{baseDir}/templates/python/`: Python code templates with type hints
- `{baseDir}/templates/go/`: Go code templates with struct definitions

### Generator Script
- `{baseDir}/scripts/generate.py`: Main code generator
  - Arguments: --spec PATH, --lang LANG, --output DIR, --auth TYPE
  - Output: JSON with {file: path, content: code} entries
  - Dependencies: PyYAML, Jinja2, openapi-spec-validator

### Reference Documentation
- `{baseDir}/references/openapi-spec.md`: OpenAPI 3.x specification guide
- `{baseDir}/references/template-syntax.md`: Jinja2 template customization guide

## Configuration

### Optional Settings
Edit `{baseDir}/config.json`:
```json
{
  "default_language": "typescript",
  "include_tests": true,
  "naming_convention": "camelCase",
  "error_handling": "exceptions",
  "timeout_seconds": 30
}
```

## Testing This Skill

### Manual Test
1. Create test spec: `workspace/test-api.yaml` (simple OpenAPI 3.0 spec)
2. Invoke: `/api-integration-generator test-api.yaml typescript ./output`
3. Verify output contains: client.ts, types.ts, README.md
4. Check generated code compiles without errors

### Automated Test
Run: `Bash python {baseDir}/scripts/test_generator.py`
Expected: All test specs generate valid code, 100% coverage
```

## Token Optimization (Safe Reductions Only)

### ✅ Safe to Optimize
- Reduce example count if pattern clear from 1-2
- Shorten section headings
- Remove redundant explanations
- Consolidate similar error scenarios

### ❌ Never Optimize Away
- {baseDir} references (breaks portability)
- allowed-tools specifications (security critical)
- Error handling sections (user needs troubleshooting)
- Prerequisites (user needs requirements)
- Concrete instruction steps (clarity essential)

## References

This mode incorporates best practices from:
- OpenCode skills documentation[1][146]
- Claude Code skills architecture[8][131]
- Agent skills development guide[134][137]
- Progressive disclosure patterns[131]
- Tool permission security principles[1][134]
