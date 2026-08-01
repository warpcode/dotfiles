---
name: github-cli
description: >
  Unified GitHub CLI and API wrapper for managing issues, pull requests, and reviews.
  Use this skill whenever the user wants to interact with GitHub: open/update/view/list/search
  issues or PRs, submit reviews, resolve review threads, check CI status, or perform
  pre-merge checks. It provides a robust interface that prioritizes 'gh' CLI and
  falls back to direct API calls if needed.
---

# GitHub CLI

Unified capability for managing GitHub issues, pull requests, and reviews end-to-end.

## 🛠️ Common Client

All scripts in this skill leverage a shared client at `scripts/common/client.sh` which:
- Prioritizes `gh` CLI if installed and authenticated.
- Falls back to `curl` with `GITHUB_TOKEN` if `gh` is unavailable.
- Standardizes GraphQL and REST API requests.

## 📝 Pull Requests & Reviews

### Workflow
1. **Pre-flight**: Run `scripts/prs/preflight.sh` to check auth, branch status, and existing PRs.
2. **Context**: Run `scripts/prs/get_pr_context.sh <owner> <repo> <pr_number>` to get OID, stats, and files.
3. **Audit**: Inspect the diff and CI status (`gh pr checks`).
4. **Review**:
   - Batch threads with `scripts/prs/fetch_all_pr_threads.sh`.
   - Submit review with `scripts/prs/submit_review.sh`.
   - Resolve threads with `scripts/prs/resolve_review_thread.sh`.
5. **Pre-merge**: Run `scripts/prs/pre_merge_checks.sh <pr_number>` before approving or merging.

### Guidelines
- **Draft First**: Always create PRs as drafts.
- **Never from main**: Never create PRs from `main` or `master` branches.
- **Body Files**: Always use `--body-file` with a temporary file written via your native tool.
- **Non-Invasive**: Perform reviews without checking out branches.
- **Approval Constraints**: Never add NEW comments when approving. Just state approval.

## 🐛 Issues

### Workflow
1. **Determine Action**: Create, update, comment, close, or list.
2. **Gather Context**: Identify repo, labels, milestones, and templates.
3. **Structure Content**: Use templates if available; otherwise, use fallback templates in `references/`.
4. **Review**: Present the full issue/comment to the user for approval.
5. **Execute**: Use `gh issue` commands or fallback to API.

### Body Text
You MUST use `--body-file` for any command needing body text (create, edit, comment).
1. Write the content to a temporary markdown file via your native **file writing tool**.
2. Pass the file path to the command's `--body-file` flag.

## 🚀 Operations & Resources

| Operation | Script / Resource |
|-----------|-------------------|
| **PR Pre-flight** | `scripts/prs/preflight.sh` |
| **PR View** | `scripts/prs/view_pr.sh` |
| **PR Context** | `scripts/prs/get_pr_context.sh` |
| **Submit Review** | `scripts/prs/submit_review.sh` |
| **Resolve Thread** | `scripts/prs/resolve_review_thread.sh` |
| **Fetch Threads** | `scripts/prs/fetch_all_pr_threads.sh` |
| **Pre-merge Checks** | `scripts/prs/pre_merge_checks.sh` |
| **Fetch File** | `scripts/prs/fetch_file.sh` |
| **Templates** | `templates/` |
| **References** | `references/` |

## 🧠 Constraints
- **Confirm Before Executing**: Always present the full content/review to the user and wait for approval.
- **Token Efficiency**: Use summarized script outputs unless raw output is strictly required for debugging.
- **Neutral Tone**: Maintain a strictly neutral and formal tone in all comments and reviews.
