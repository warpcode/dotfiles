# Ticket Authoring & Slicing Reference Guide

Guide for breaking down features into vertical slices, formulating unambiguous acceptance criteria, sizing tickets, and provisioning them in issue trackers.

---

## 1. Vertical Slicing vs. Horizontal Layering

Horizontal layering (e.g., "Ticket 1: Write all DB schemas", "Ticket 2: Write all backend APIs", "Ticket 3: Build UI") is an anti-pattern:
- No working software is delivered until the very end.
- Feedback loops are delayed until late in the cycle.
- Merge conflicts and integration bugs explode.

**Vertical Slicing Rule**: Every Story or Task must cut vertically through all required layers to deliver one thin, independently testable behavior:
```text
┌──────────────────────────────────────────────┐
│                  Frontend UI                 │
├──────────────────────────────────────────────┤
│               Service / API                  │   ▲ Vertical Slice (1-2 pt)
├──────────────────────────────────────────────┤   │ Cuts through all layers
│              Database / Config               │   │ to ship one complete action
└──────────────────────────────────────────────┘
```

---

## 2. The 3-Factor Sizing Heuristic

Size tickets by evaluating **Complexity**, **Effort**, and **Uncertainty**:

| Complexity | Effort | Uncertainty | Points | Action |
|---|---|---|---|---|
| Low | Small | Low | **0.5 pt** | Trivial fix, config update, or single test. |
| Low–Med | Small–Med | Low | **1.0 pt** | Standard single-PR vertical slice. |
| Medium | Medium | Low–Med | **2.0 pt** | Multi-file vertical slice, well-understood patterns. |
| Med–High | Med–High | Low | **3.0 pt** | Maximum permissible ticket size for an isolated engineer/agent. |
| **Any** | **Large** | **High** | **$\ge$ 5.0 pt** | **Too Large / Ambiguous**: Split into a Spike (ADR) + smaller tasks. |

---

## 3. Strict Acceptance Criteria (Given / When / Then)

Acceptance criteria must leave zero room for hallucination or interpretation:

### Template:
- **Given** [concrete initial state, database fixture, or mock condition],
- **When** [specific method, API endpoint, or CLI command is executed with exact parameters],
- **Then** [deterministic observable outcome: return code, response payload, persisted record, or error format].

### Rules:
1. Every story must have at least one **Happy Path** AC and one **Failure Mode / Edge Case** AC.
2. Avoid passive criteria like "Should be fast" or "Should handle errors cleanly". Specify "Response time < 100ms" or "Returns HTTP 400 with `INVALID_ARGUMENT` JSON".

---

## 4. Traceability & Commit/PR Linkage

Link commits and pull requests to their owning work items using the repository's active convention—no single format is mandatory:

- **GitHub Issue-First**: Reference issues in PR bodies and commit messages (`Closes #102`, `Refs #101`, `Part of #100`) and record dependency edges (`Depends on #101`, `Blocked by #101`).
- **Jira**: Include the Jira issue key (`PROJ-102`) in branch names, PR titles, or commit messages.
- **Local Plan Trailer (Optional)**: When tracking against an in-repo `docs/plans/` spec, include the canonical trailer in the commit or PR body:

```text
feat(sandbox): enforce plugin memory limits

Isolate plugin execution in dedicated cgroup with 512MB threshold.

Closes #102
Plan: plugin-sandbox:TSK-102
```

Using consistent issue keys, PR references, or optional `Plan:` trailers allows `project-tracker` to reconcile tracker state, branch/PR topology, and code ground truth automatically.
