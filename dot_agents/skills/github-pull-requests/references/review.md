# Review Pull Request

Add line-level comments and a final review status (APPROVE, REQUEST_CHANGES, or COMMENT) to a pull request.

## Process

### 1. Identify Target
Ensure you have the PR number and repository context.

### 2. Fetch Latest Commit ID
Reviews must be pinned to the latest commit OID of the PR's head branch.
```bash
gh pr view <number> --json headRefOid --template '{{.headRefOid}}'
```

### 3. Map Review Findings
For each finding, identify:
- `path`: Relative file path.
- `line`: The line number in the *final version* of the file (not the diff line).
- `body`: The descriptive, actionable comment.

### 4. Construct JSON Payload
Create a temporary file (e.g., `review_payload.json`) with the following structure:
```json
{
  "commit_id": "<HEAD_REF_OID>",
  "body": "<SUMMARY_MESSAGE>",
  "event": "APPROVE | REQUEST_CHANGES | COMMENT",
  "comments": [
    {
      "path": "path/to/file",
      "line": 10,
      "body": "Comment text"
    }
  ]
}
```

### 5. Confirm with User
Present the final review findings to the user using the **Mandatory Approval Template** below.
**You MUST obtain explicit permission before proceeding to the submission step.**

#### Mandatory Approval Template
```markdown
## Summary
<A brief overview of the review's goal and overall assessment>

## Review Findings (Brief)
<List findings in caveman-style: filepath:L<line>: <severity> <type>: <short_description>>
- example.sh:L10: 🔵 nit: inconsistent naming. Use camelCase.

## Review Comments

### <filepath>
**Lines**: <start>-<end>
**Type**: <bug|risk|nit|q>
**Severity**: <High|Medium|Low>

**Issue**:
<Detailed explanation of the problem>

**Code**:
```<lang>
<Snippet of the problematic code>
```

**Solution**:
<Detailed recommendation for the fix>
```<lang>
<New code snippet (if the fix is simple/surgical)>
```

## Conclusion
<Final recommendation: e.g., Approve with nits, Request changes, etc.>
```

### 6. Submit Review
Use the GitHub API to submit the review in a single transaction.
```bash
gh api repos/:owner/:repo/pulls/:number/reviews --input review_payload.json
```

### 6. Cleanup
Delete the temporary JSON payload file.

## Guidelines for Comments
- **Actionable**: Ensure an LLM or developer can implement the fix directly from the comment.
- **Specific**: Reference exact symbol names, Zsh built-ins, or coding standards.
- **Consolidated**: Use a single review with multiple comments rather than many individual comments.
