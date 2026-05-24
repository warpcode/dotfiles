---
name: technical-review-guidelines
description: "Guidelines for writing high-quality technical reviews. Use this skill whenever you are asked to review code, PRs, architecture designs, or technical documentation. It mandates a specific structure for findings, a neutral tone, and precise location references."
---

# Technical Review

Follow these guidelines to provide structured, actionable, and professional technical reviews.

## 🧠 Behavioral Guidelines

1.  **Strictly Neutral & Formal Tone**:
    *   Avoid conversational filler ("I think", "maybe", "pretty good").
    *   Avoid encouraging or affirming remarks ("LGTM", "Nice work").
    *   Focus exclusively on technical findings, rationale, and corrections.
    *   Never use 'caveman' style or informal language.

2.  **No Proactive Refactoring**:
    *   Do not modify code unless explicitly instructed.
    *   Proposed solutions should be suggestions, not implementations applied to the codebase.

3.  **Non-Invasive Inspection**:
    *   Perform reviews without checking out branches or mutating the local state unless necessary and without explicit user approval.
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
*   **Medium**: Functional defects, significant performance issues, style guide violations that impact maintainability.
*   *Low**: Minor optimizations, readability improvements, nitpicks.

### **Description**
A clear, concise explanation of the issue. Use plain English. If applicable, include an extract of the original error message or sample code that illustrates the problem.

### **Impact**
Explain WHY this is a problem. Describe the consequences for security, performance, stability, or maintainability.

### **Proposed Solution**
Provide a technical fix. 
*   **If the solution is known**: Include a code example clarifying the implementation.
*   **If the solution is unknown**: Suggest a specific investigation or diagnostic path.

## 📋 Review Procedures

1.  **Discovery**: Identify all areas requiring review (changed files in a PR, modules in an architecture, etc.).
2.  **Audit**: Systematically evaluate each area against:
    *   Functional correctness and requirements.
    *   Security best practices.
    *   Performance and efficiency.
    *   Style guidelines and project conventions.
    *   Readability and maintainability.
3.  **Drafting**: Consolidate all findings. Use line-level comments for specific issues and file/document-level comments for cross-cutting concerns.
4.  **Verification**: If addressing previous feedback, verify the fix in the current state before resolving.
5.  **Approval/Rejection**: 
    *   If approving, do not add NEW comments. Just state the approval.
    *   If rejecting, provide the structured list of findings that must be addressed.
