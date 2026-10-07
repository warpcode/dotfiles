# GitHub Organizations, Teams & User Identity

Query authenticated user information, organization teams, and team membership.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **Get current user** | Read-Only | `get_me` | `gh api user` |
| **Get organization teams** | Read-Only | `get_teams` | `gh api orgs/{org}/teams` |
| **Get team members** | Read-Only | `get_team_members` | `gh api orgs/{org}/teams/{team_slug}/members` |

---

## 1. User Identity (`get_me`)

Inspect the currently authenticated user account:

```bash
gh api user
```

---

## 2. Organization Teams (`get_teams`)

List all teams within an organization:

```bash
gh api orgs/<org_name>/teams
```

---

## 3. Team Members (`get_team_members`)

List members of a specific organization team:

```bash
gh api orgs/<org_name>/teams/<team_slug>/members
```
