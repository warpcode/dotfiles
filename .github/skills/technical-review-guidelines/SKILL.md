---
name: technical-review-guidelines
description: "Guidelines for writing high-quality technical reviews. Use this skill whenever you are asked to review code, PRs, architecture designs, or technical documentation. It mandates a specific structure for findings, a neutral tone, precise location references, and strictly defined commentary constraints."
---

# Technical Review Guidelines

Follow these guidelines to provide structured, actionable, and professional technical reviews. This skill enforces the established standard for code reviews and architectural audits across the workspace.

## 🧠 Behavioral Guidelines

1.  **Strictly Neutral & Formal Tone**:
    *   Avoid conversational filler ("I think", "maybe", "pretty good").
    *   Avoid encouraging or affirming remarks ("LGTM", "Nice work").
    *   Focus exclusively on specific technical findings, rationale, and corrections.
    *   Never use 'caveman' style or informal language.

2.  **Commentary Constraints**:
    *   **No Summaries**: Do not provide summaries of work done if it was explicitly requested by the user or is already visible in the PR. Provide *only* the technical review findings. Do not paraphrase the task or the developer's work.
    *   **Replies**: Only reply to comments if needed (and with user approval). Give a thumbs up (👍) ONLY if the developer replied saying they fixed a requested change.
    *   **Resolution**: Proactively resolve review threads once the corresponding changes have been verified in the diff. If the developer asks a question, alert the user for a response.
    *   **Approvals**: If approving a pull request, NEVER add NEW comments to files. Do not provide a summary if there is nothing new to add; just ask to approve.

3.  **No Proactive Refactoring**:
    *   Do not modify code unless explicitly instructed.
    *   Proposed solutions should be suggestions, not implementations applied directly to the codebase.

4.  **Non-Invasive Inspection**:
    *   Perform reviews without checking out branches or mutating the local state unless necessary.
    *   Use remote diffs and API-based file fetching where possible.

## 📝 Finding Structure

Each technical finding MUST follow this mandatory structure:

### `[Location Descriptor]`
Provide a precise reference to WHERE the issue is.
*   **Format**: `file:lineStart-lineEnd` or a specific URL/symbol name.
*   **Example**: `src/auth/service.ts:45-52`

### **Severity**: `[High | Medium | Low]`
Categorize the issue based on its impact.
*   **High**: Critical bugs, security vulnerabilities, major architectural flaws.
*   **Medium**: Functional defects, significant performance issues, style guide violations that impact maintainability, missing return codes.
*   **Low**: Minor optimizations, readability improvements, nitpicks.

### **Description**
A clear, concise explanation of the issue. Use plain English. If applicable, include an extract of the original error message or sample code that illustrates the problem.

### **Impact**
Explain WHY this is a problem. Describe the consequences for security, performance, stability, or maintainability.

### **Proposed Solution**
Provide a technical fix. 
*   **If the solution is known**: Include a code example clarifying the implementation.
*   **If the solution is unknown**: Suggest a specific investigation or diagnostic path.

## 📋 Review Procedures

1.  **Discovery**: Identify all areas requiring review. If it is a PR or Issue, cross-reference original requirements.
2.  **Audit & Prioritization**: Systematically evaluate each area, prioritizing in this order:
    *   Bugs and functional correctness.
    *   Security issues.
    *   Style guideline violations.
    *   Performance and efficiency improvements.
    *   Readability and maintainability.
    *   Anti-patterns and duplication.
    *   Consistency with project conventions.
    *   Whether the changes meet the original issue requirements.
    *   Unresolved PR comments and review questions.
3.  **Drafting**: Consolidate all findings. Use line-level comments for specific issues and file/document-level comments for cross-cutting concerns. If nothing is wrong, do not add any comments.
4.  **Verification**: If addressing previous feedback, verify the fix in the current state before resolving threads.
5.  **Approval/Rejection**: 
    *   If approving, do not add NEW comments. Just state the approval.
    *   If rejecting, provide the structured list of findings that must be addressed.