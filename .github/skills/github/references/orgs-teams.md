# GitHub Organizations, Teams & User Identity

Query authenticated user information, organization teams, and team membership.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh` / `gh api`) |
| :--- | :--- | :--- | :--- |
| **Get current user** | Read-Only | `get_me` | `gh api user` / `gh auth status` |
| **Get organization teams** | Read-Only | `get_teams` | `gh api orgs/{org}/teams` |
| **Get team members** | Read-Only | `get_team_members` | `gh api orgs/{org}/teams/{team_slug}/members` |

---

## 1. User Identity (`get_me`)

Inspect the currently authenticated user account, permissions, and scopes:

```bash
# Verify authentication status and active account
gh auth status

# Get authenticated user profile JSON
gh api user --jq '{login: .login, name: .name, id: .id, email: .email}'

# Check OAuth scopes
gh api user -i | grep -i "x-oauth-scopes"
```

---

## 2. Organization Teams (`get_teams`)

List all teams within an organization:

```bash
# List teams with slug, name, and description
gh api orgs/{org}/teams --paginate --jq '.[] | {name: .name, slug: .slug, description: .description}'
```

---

## 3. Team Members (`get_team_members`)

List members of a specific organization team:

```bash
# List team members by role (member, maintainer, all)
gh api orgs/{org}/teams/{team_slug}/members --jq '.[].login'

# Filter maintainers only
gh api "orgs/{org}/teams/{team_slug}/members?role=maintainer" --jq '.[].login'
```
