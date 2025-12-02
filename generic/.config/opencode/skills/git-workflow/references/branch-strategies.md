# Branch Management Strategies

**Git Branch Strategy Expert**. Recommend branch strategies and branch namings for new features/bugs.

## Git Flow

**Best for:** Projects with scheduled releases, multiple versions in production

**Structure:**
- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features (branch from develop)
- `release/*` - Release preparation (branch from develop)
- `hotfix/*` - Emergency fixes (branch from main)

**Workflow:**
1. Create feature branch from develop
2. Merge feature to develop when complete
3. Create release branch when ready to ship
4. Merge release to both main and develop
5. Tag main with version number

**Pros:** Clear structure, supports multiple releases
**Cons:** Complex, overhead for small teams

## Trunk-Based Development

**Best for:** CI/CD environments, fast iteration, experienced teams

**Structure:**
- `main` - Always deployable
- `feature/*` - Short-lived (1-2 days max)

**Workflow:**
1. Branch from main for small changes
2. Merge to main frequently (daily)
3. Use feature flags for incomplete work
4. Deploy from main automatically

**Pros:** Simple, fast feedback, less merge pain
**Cons:** Requires discipline, good CI/CD, feature flags

## GitHub Flow

**Best for:** Web applications, continuous deployment

**Structure:**
- `main` - Always deployable
- `feature/*` - Any new work

**Workflow:**
1. Branch from main
2. Make changes and commit
3. Open pull request for discussion
4. Deploy from branch to test
5. Merge to main after approval
6. Deploy immediately

**Pros:** Simple, works with CD, good for small teams
**Cons:** Can get messy with long-lived branches

## Work-Based Strategy

**Best for:** Corporate environments, strict naming conventions

**Structure:**
- `main`/`master` - Production-ready code
- No separate develop branch
- Branches based on JIRA tickets or epics

**Branch Naming Rules:**
- **ONLY** lowercase letters, numbers, and hyphens
- No uppercase letters, underscores, or special characters
- **Main Epic:** Use JIRA epic ticket (e.g., `tic-6482`)
- **Epic with Sub-tickets:** `epic-ticket-subticket` (e.g., `tic-3456-tic3457`)
- **Descriptive with Ticket:** `description-ticket` (e.g., `new-admin-page-tic-4567`)
- **Hotfix:** Always `hotfix-tiny-descriptive-name` (e.g., `hotfix-login-bug`, `hotfix-api-timeout`)
- Examples: `tic-6482`, `tic-3456-tic3457`, `new-admin-page-tic-4567`, `hotfix-login-bug`

**Commit Message Rules:**
- If NOT on main/master branch: Prefix with `[branch-name]`
- Format: `[branch-name] commit message`
- Example: `[abc-123] fix login validation`

**Workflow:**
1. ALWAYS request JIRA ticket link or name when creating branches
2. If branching from main/master: Create branch with JIRA-based naming
3. If branching from non-main/master branch: Use source branch as prefix + JIRA info
4. Work on feature/fix
5. Prefix commits with branch name when not on main/master
6. Merge following company approval process

**Pros:** Consistent naming, traceable commits, corporate compliance
**Cons:** Restrictive, requires discipline, manual prefixing

## Ship/Show/Ask

**Best for:** Open source, teams with varying experience levels

**Three types of changes:**
- **Ship:** Merge without review (typos, config)
- **Show:** Merge then notify team (refactoring)
- **Ask:** Request review before merge (features, breaking changes)

**Workflow:**
1. Assess change impact
2. Choose appropriate level
3. Follow that level's process

**Pros:** Flexible, reduces review burden
**Cons:** Requires judgment, cultural buy-in

## General Branch Naming Conventions

**Format:** `/-`

Examples:
- `feature/AUTH-123-oauth-login`
- `fix/CART-456-price-calculation`
- `docs/update-api-guide`
- `refactor/payment-service`
- `hotfix/security-patch`

**Types:**
- feature - New functionality
- fix - Bug fixes
- docs - Documentation
- refactor - Code restructuring
- test - Test additions/changes
- chore - Build/tooling changes
- hotfix - Production emergency fixes

**Note:** Work-Based Strategy has its own specific naming rules that take priority when that strategy is selected.

## Decision Guide

### Warpcode User Logic

**If current user is Warpcode:**
- Check if `develop` branch exists:
  - If `develop` exists → Use **Git Flow**
  - If `develop` doesn't exist → Use **GitHub Flow**

**If current user is NOT Warpcode:**
- Check if $IS_WORK environment variable is 1:
  - If $IS_WORK = 1 → Use **Work-Based Strategy**
  - If $IS_WORK ≠ 1 → TODO: Add fallback strategy

### Standard Decision Criteria

**Choose Git Flow if:**
- Multiple production versions maintained
- Scheduled release cycles
- Need formal release process
- Large team (10+)
- **OR:** Warpcode user + develop branch exists

**Choose Trunk-Based if:**
- Continuous deployment
- Mature CI/CD pipeline
- Small, experienced team
- Need fast iteration

**Choose GitHub Flow if:**
- Web application
- Single production version
- Want simplicity
- Medium team (3-10)
- **OR:** Warpcode user + no develop branch

**Choose Work-Based Strategy if:**
- User is NOT Warpcode
- $IS_WORK = 1
- Corporate environment
- Need strict naming conventions
- JIRA integration required

**Choose Ship/Show/Ask if:**
- Open source project
- Mixed experience levels
- Want to reduce review overhead
- Trust-based culture
```
