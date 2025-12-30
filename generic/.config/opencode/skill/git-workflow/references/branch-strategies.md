# Branch Management Strategies

## Rules

### Phase 1: Clarification
IF strategy.ambiguous -> Ask(user: team size, release model, CI/CD) -> Wait(User_Input)

### Phase 2: Planning
Analyze(repo structure + team + workflow) -> Recommend(strategy) -> Explain(rationale)

### Phase 3: Execution
Provide(naming conventions + workflow steps)

### Phase 4: Validation
Strategy matches constraints? IF Fail -> Suggest(alternative)

## Context

**Dependencies**: git (CLI), repository structure

**Threat Model**:
- Input -> Sanitize(branch_names) -> Validate(no_special_chars) -> Execute
- Rule: Enforce naming conventions before branch creation

## Strategy Decision Logic

```
# Get current git username
user = git config user.name

IF user == "Warpcode":
  IF develop branch exists:
    -> Use Git Flow
  ELSE:
    -> Use GitHub Flow

ELSE IF user != "Warpcode":
  IF $IS_WORK == 1:
    -> Use Work-Based Strategy
  ELSE:
    -> Fallback to GitHub Flow
```

**Note**: "user" refers to `git config user.name` (git username)

## Git Flow

**Best for**: Scheduled releases, multiple production versions

**Structure**:
```
main     - Production-ready
develop  - Integration branch
feature/* - New features (from develop)
release/* - Release prep (from develop)
hotfix/*  - Emergency fixes (from main)
```

**Workflow**:
1. Create feature from develop
2. Merge feature to develop
3. Create release from develop
4. Merge release to main + develop
5. Tag main with version

**Pros**: Clear structure, supports releases
**Cons**: Complex, overhead for small teams

**Choose IF**:
- Multiple production versions
- Scheduled releases
- Large team (10+)

## Trunk-Based Development

**Best for**: CI/CD, fast iteration, experienced teams

**Structure**:
```
main     - Always deployable
feature/* - Short-lived (1-2 days max)
```

**Workflow**:
1. Branch from main
2. Merge frequently (daily)
3. Use feature flags for WIP
4. Deploy from main automatically

**Pros**: Simple, fast feedback, less merge pain
**Cons**: Requires discipline, good CI/CD, feature flags

**Choose IF**:
- Continuous deployment
- Mature CI/CD pipeline
- Small, experienced team
- Fast iteration

## GitHub Flow

**Best for**: Web apps, continuous deployment

**Structure**:
```
main     - Always deployable
feature/* - Any new work
```

**Workflow**:
1. Branch from main
2. Make changes + commit
3. Open PR for discussion
4. Deploy from branch to test
5. Merge after approval
6. Deploy immediately

**Pros**: Simple, works with CD, good for small teams
**Cons**: Messy with long-lived branches

**Choose IF**:
- Web application
- Single production version
- Medium team (3-10)
- Want simplicity

## Work-Based Strategy

**Best for**: Corporate, strict naming, JIRA

**Structure**:
```
main/master  - Production-ready
[No separate develop]
```

**Branch Naming**:
- **ONLY**: lowercase, numbers, hyphens
- **NO**: uppercase, underscores, special chars
- **Main Epic**: JIRA epic (e.g., `tic-6482`)
- **Epic + Sub**: `epic-ticket-subticket` (e.g., `tic-3456-tic3457`)
- **Descriptive**: `description-ticket` (e.g., `new-admin-page-tic-4567`)
- **Hotfix**: `hotfix-tiny-descriptive-name` (e.g., `hotfix-login-bug`)

**Commit Messages**:
- Off main/master: `[branch-name] message`
- Example: `[abc-123] fix login validation`

**Workflow**:
1. Request JIRA ticket link/name
2. Branch from main/master with JIRA naming
3. Prefix commits with branch name (off main)
4. Merge per approval process

**Pros**: Consistent naming, traceable, corporate compliance
**Cons**: Restrictive, requires discipline, manual prefixing

**Choose IF**:
- Corporate environment
- Strict naming required
- JIRA integration
- User != Warpcode && $IS_WORK == 1

## Ship/Show/Ask

**Best for**: Open source, mixed experience

**Change Types**:
- **Ship**: Merge without review (typos, config)
- **Show**: Merge then notify (refactoring)
- **Ask**: Review before merge (features, breaking)

**Workflow**:
1. Assess impact
2. Choose level
3. Follow process

**Pros**: Flexible, reduces review burden
**Cons**: Requires judgment, cultural buy-in

**Choose IF**:
- Open source project
- Mixed experience levels
- Reduce review overhead
- Trust-based culture

## General Naming

**Format**: `type/description-ticket`

**Types**:
- `feature` - New functionality
- `fix` - Bug fixes
- `docs` - Documentation
- `refactor` - Code restructuring
- `test` - Test additions
- `chore` - Build/tooling
- `hotfix` - Production emergency

**Examples**:
- `feature/AUTH-123-oauth-login`
- `fix/CART-456-price-calculation`
- `docs/update-api-guide`
- `refactor/payment-service`
- `hotfix/security-patch`

**Note**: Work-Based Strategy has its own rules (above)

## Decision Guide

### Warpcode Logic

| Condition | Strategy |
|-----------|----------|
| Warpcode + develop exists | Git Flow |
| Warpcode + no develop | GitHub Flow |

### Non-Warpcode Logic

| Condition | Strategy |
|-----------|----------|
| $IS_WORK == 1 | Work-Based |
| $IS_WORK ≠ 1 | GitHub Flow (fallback) |

### Standard Criteria

| Choose Git Flow IF | Choose Trunk-Based IF | Choose GitHub Flow IF | Choose Work-Based IF | Choose Ship/Show/Ask IF |
|--------------------|-----------------------|-----------------------|----------------------|-------------------------|
| Multiple production versions | Continuous deployment | Web application | Corporate environment | Open source project |
| Scheduled releases | Mature CI/CD | Single production version | Strict naming | Mixed experience |
| Formal release process | Small experienced team | Medium team (3-10) | JIRA integration | Reduce review overhead |
| Large team (10+) | Fast iteration | Want simplicity | User != Warpcode + IS_WORK | Trust-based culture |

## Examples

### Example 1: Git Flow (Warpcode)
Context: Warpcode, develop branch exists
Strategy: Git Flow
Workflow: feature from develop, merge to develop, release to main

### Example 2: Work-Based Strategy (Corporate)
Context: Corporate, JIRA tickets
Strategy: Work-Based
Naming: `tic-6482`, `new-admin-page-tic-4567`, `hotfix-login-bug`

### Example 3: GitHub Flow (Web Startup)
Context: Web startup, CD pipeline
Strategy: GitHub Flow
Workflow: branch from main, PR, merge, deploy
