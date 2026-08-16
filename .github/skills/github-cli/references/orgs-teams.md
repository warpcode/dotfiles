# GitHub Organizations, Teams & User Identity

Query authenticated user information, organization teams, and team membership.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | Script Fallback (`${SKILL_DIR}/scripts/`) |
| :--- | :--- | :--- | :--- |
| **Get current user** | Read-Only | `get_me` | `get_me.sh` |
| **Get organization teams** | Read-Only | `get_teams` | `get_teams.sh` |
| **Get team members** | Read-Only | `get_team_members` | `get_team_members.sh` |

---

## 1. User Identity (`get_me`)

Inspect the currently authenticated user account:

```bash
bash ${SKILL_DIR}/scripts/get_me.sh
```

---

## 2. Organization Teams (`get_teams`)

List all teams within an organization:

```bash
bash ${SKILL_DIR}/scripts/get_teams.sh --org <org_name>
```

---

## 3. Team Members (`get_team_members`)

List members of a specific organization team:

```bash
bash ${SKILL_DIR}/scripts/get_team_members.sh --org <org_name> --team-slug <team_slug>
```
