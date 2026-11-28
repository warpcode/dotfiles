---
name: project-lifecycle
description: "End-to-end project lifecycle orchestrator delegating planning, epic DAG execution, implementation, review, and merge workflows to specialized agents."
---

# Project Lifecycle Orchestrator

Coordinate a software initiative from initial requirements through architecture, ticket execution, code review, and final merge using real `.github/agents/*.agent.md` specialists and their domain Knowledge Centres.

## Agent Roster

Delegate strictly to existing repository agents — never invent or call unconfigured agent names:

| Role | Agent | Responsibility |
|---|---|---|
| Architecture & planning | `project-architect` | Socratic stress-testing, `SPEC.md` (EARS), MADR ADRs (`docs/adr/`), vertical-slice ticket/epic decomposition |
| Multi-issue DAG orchestration | `epic-orchestrator` | Epic-tree vs. mainline selection, dependency DAG readiness frontier, parent-base propagation, 3-way reconciliation |
| Single-ticket implementation | `software-engineer` | Isolated worktree implementation from explicit parent base ref, TDD/validation (`./validate.sh`), draft PR prep |
| Audit & code review | `code-reviewer` | Read-only PR audit (`code-review`, `code-security-audit`, `github` scripts), inline findings, review submission |
| Git & merge operations | `git-specialist` | Branch-tree audits (`audit_repo_branches.py`), `branch_base_check.sh`, conflict triage (`merge_state.sh`), cascading `--onto` rebases, PR retargeting, merges |
| Optional domain helpers | `ai-specialist`, `web-researcher` | AI customization refactors/validation (`ai-authoring`) or authoritative external docs lookup |

## Branching Mode Selection

Select the branching strategy before dispatching implementation work:

```mermaid
flowchart TD
  Start["1. Plan & Decompose (project-architect)"] --> Mode{"2. Initiative Scope"}
  Mode -- "Single standalone ticket" --> Mainline["Mainline / Trunk Streaming (base: origin/<default-branch>)"]
  Mode -- "Multi-issue or dependent epic" --> Epic["Epic-Tree & Dependency-Stacked (epic-orchestrator)"]
  Mainline --> Impl["3. Implement in isolated worktree (software-engineer)"]
  Epic --> Ready["Compute ready frontier & parent base (epic/<id>-<slug> or upstream branch)"]
  Ready --> Impl
  Impl --> Review["4. Adversarial audit against exact parent base (code-reviewer)"]
  Review -- "Findings exist" --> Impl
  Review -- "Approved & green" --> Merge["5. Merge up / retarget / reconcile (git-specialist + epic-orchestrator)"]
```

- **Mainline / Trunk Streaming**: Use for standalone single-ticket work. Branch directly from `origin/<default-branch>`, implement in an isolated worktree, review against `origin/<default-branch>`, and squash-merge.
- **Epic-Tree & Dependency-Stacked**: Use for multi-issue initiatives or tickets with `Depends on #N` / `Blocked by #N` blockers. Hand off the approved epic and dependency graph to `epic-orchestrator` to manage `epic/<id>-<slug>`, dispatch independent ready tickets in parallel, and stack dependent branches off upstream branches.

## Lifecycle Phases

### Phase 1: Socratic Architecture, Spec & Decomposition (`project-architect`)
1. Invoke `project-architect` with the user's requirements (or existing `SPEC.md`/epic for resumption).
2. Relay any open questions to the user until requirements, `NG-*` non-goals, EARS acceptance criteria, and any required ADRs lock.
3. Have `project-architect` produce vertical-slice ticket specs and dependency links (`Depends on #N` / `Blocked by #N`).
4. **Gate**: Obtain explicit user approval on the plan, ADRs, and ticket breakdown before creating remote issues or starting implementation.

### Phase 2: Implementation Dispatch (`epic-orchestrator` / `software-engineer`)
1. **Multi-issue epic**: Delegate to `epic-orchestrator`, which creates/tracks `epic/<id>-<slug>` off `origin/<default-branch>`, computes the unblocked ready frontier, and dispatches `software-engineer` per ready ticket with its exact `--base` ref (`epic/<id>-<slug>` or completed upstream dependency branch).
2. **Single standalone ticket**: Dispatch `software-engineer` directly in an isolated worktree branched from `origin/<default-branch>`.
3. Require `bash .github/skills/git-expert/scripts/branch_base_check.sh --base <parent-ref> --head <branch>` and `./validate.sh` (plus targeted suites) to pass before opening or updating the draft PR (`--base <parent-ref> --body-file ...`).

### Phase 3: Specialist Audit & Code Review (`code-reviewer`)
1. Invoke `code-reviewer` against the PR (using `github/scripts/pr_audit_bundle.sh` or `github/scripts/prebundle_prs.sh` for multi-PR batches) and its real `baseRefName`.
2. `code-reviewer` evaluates functionality, architecture, performance, TDD/mutation coverage, and security (`code-review`, `code-security-audit`) and prepares findings (`github/scripts/submit_review.sh`).
3. If `REQUEST_CHANGES` or any finding exists, route findings back to `software-engineer` in the owning branch/worktree and repeat verification.

### Phase 4: Merge-Up, Retargeting & Reconciliation (`git-specialist` & `epic-orchestrator`)
1. **Gate**: Present final verification results (`./validate.sh`, CI status, `github/scripts/pr_state_rollup.py`) and obtain explicit user approval before pushing, retargeting, merging, or closing issues.
2. Have `git-specialist` execute approved bottom-up merges (`github/scripts/pr_merge.sh` or `batch_merge.sh`), retarget dependent PRs (`gh pr edit --base`), cascade `--onto` rebases if upstream was squashed, and resolve any conflicts (`git-expert/scripts/merge_state.sh` first).
3. For epics, have `epic-orchestrator` run 3-way reconciliation (`Tracker <-> Branch/PR Tree <-> Code`) before final epic merge and closure.

## Operational Guardrails

- **No Phantom Agents or Scripts**: Delegate only to `.github/agents/*.agent.md` agents and execute only real scripts under `.github/skills/*/scripts/`.
- **Explicit Approval Gates**: NEVER run `git push`, `gh pr create`, `gh pr merge`, `gh pr edit --base`, `git branch -D`, or close issues without explicit user approval.
- **Exact Parent Lineage**: Always pass and verify `--base <parent-ref>` across worktree creation, `branch_base_check.sh`, PR creation, and review bundles.
