---
description: Perform an isolated deep security and dependency audit
argument-hint: "[target-directory]"
agent: security-auditor
subtask: true
model: gemini-3.5-flash
---

# Isolated Security Audit Directive

Perform an in-depth security and vulnerability sweep on directory: `${1:-.}`

## Pre-Execution Inspection
Dependency audit status:
!`npm audit --json`

## Audit Directives
1. Grep for potential secret leaks, hardcoded tokens, and private keys.
2. Check file permissions on configuration files and scripts.
3. Review external API integrations for sanitization and parameter binding.

## Report Delivery
Synthesize all findings into an executive summary table listing:
- File / Line
- Vulnerability Type
- Severity (High / Medium / Low)
- Remediation Action
