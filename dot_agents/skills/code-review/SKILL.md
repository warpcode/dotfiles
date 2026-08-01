---
name: code-review
description: "Consolidated cognitive guidelines for performing highly critical, structured technical reviews. Use this skill whenever you are asked to review code, PRs, architecture designs, implementation plans, or technical documentation. It mandates a neutral tone, precise location references, and a specific structure for findings."
---

# Code Review Guidelines

Consolidated guidelines for performing rigorous, critical, and structured technical reviews.

## 🔍 Core Review Principles

1. **Be Highly Critical**: Scrutinize rigorously for edge cases, unhandled scenarios, architectural flaws, security risks, and logical inconsistencies.
2. **Fact-Based Only**: Base all feedback strictly on verifiable facts, documentation, or technical constraints.
3. **Strictly Neutral Tone**: Maintain a professional, detached, and objective tone. No conversational filler, no praise, no "LGTM".
4. **No Proactive Refactoring**: Proposed solutions should be suggestions, not implementations applied directly unless explicitly instructed.
5. **Non-Invasive**: Perform reviews without checking out branches or mutating local state where possible.

## 📝 Mandatory Finding Structure

Each technical finding MUST follow this structure:

### `[Location Descriptor]`
Precise reference: `file:lineStart-lineEnd` or symbol name.

### **Severity**: `[High | Medium | Low]`
- **High**: Critical bugs, security vulnerabilities.
- **Medium**: Functional defects, performance issues, style violations.
- **Low**: Readability improvements, nitpicks.

### **Description**
Clear, concise explanation of the issue.

### **Impact**
Explain WHY this is a problem for security, performance, or stability.

### **Proposed Solution**
Provide a technical fix or a specific investigation path.

## 📋 Review Procedures

1. **Discovery**: Identify areas requiring review (cross-reference requirements).
2. **Audit & Prioritization**: Evaluate in order: Correctness → Security → Style → Performance → Readability.
3. **Drafting**: Consolidate findings into line-level (within diff hunks) or file-level comments.
4. **Verification**: If addressing previous feedback, verify the fix before resolving threads.
5. **Approval/Rejection**:
   - **REQUEST_CHANGES**: One or more Medium or High severity findings.
   - **COMMENT**: Exclusively Low severity findings or replies.
   - **APPROVE**: No findings or all issues fully resolved. (NEVER add NEW comments when approving).

## 🧠 Behavior Guardrails

- **No Summaries**: Do not paraphrase the task or the developer's work. Provide only findings.
- **Replies**: Only reply if needed; use 👍 only if a requested change is fixed.
- **Resolution**: Proactively resolve threads once verified.
- **Line-Level Constraint**: Line-level comments MUST be within diff hunks (otherwise GitHub returns 422). Use file-level comments for issues outside hunks.
