---
name: project-tickets
description: >
  Decompose specifications, epics, PRDs, or RFCs into Epic/Sub-Issue work
  hierarchies, dependency DAGs, vertical slices, and Given/When/Then acceptance
  criteria (<= 3 pt). Use when breaking down epics, modeling dependency graphs
  and ready frontiers, mapping DAGs to branch topologies, sizing tasks, or
  authoring tickets for GitHub Issues, Jira, or optional local plans.
user-invocable: false
---

# Project Tickets

A workflow-agnostic knowledge centre for decomposing product or technical inputs
(issue-first GitHub/Jira epics, PRDs, RFCs, or optional `docs/plans/` specs)
into context-free, vertically sliced work hierarchies and acyclic dependency
graphs (DAGs).

## 1. Principles of Ticket Decomposition

1. **Vertical Slices Over Horizontal Layers**: Every ticket delivers one thin,
   testable capability cutting through all required layers (UI, service, data),
   rather than isolated horizontal layers.
2. **Strict Sizing ($\le 3$ pt)**: No ticket may exceed 3.0 points. Items
   estimated at 5+ pt contain unresolved uncertainty and must be split into a
   spike (`ADR`) and smaller tasks.
3. **Context-Free Independence**: An engineer or agent must be able to execute
   the ticket using only the ticket text, target files, upstream references, and
   linked ADRs without prior conversation context.
4. **Explicit Hierarchy & Acyclic Dependencies**: Separate parent-child scope
   containment (`Epic -> Sub-Issue -> Task`) from execution ordering (`Depends on`
   / `Blocked by`), and keep the dependency graph strictly acyclic.
5. **Flexible Traceability**: Link commits and PRs using whichever mechanism the
   repository uses—native issue references (`Closes #N`, `Refs #N`), Jira keys
   (`PROJ-123`), or optional `Plan: <slug>:<TSK-xxx>` trailers. Local
   `docs/plans/` files are optional adapters, never a prerequisite.

## 2. Decomposition Workflow

### Step 1: Ingest Source Context
Accept any structured or unstructured starting point:
- **Issue-First Epic**: An existing GitHub Epic / parent issue or Jira Epic.
- **Standalone PRD / RFC**: Feature proposal text or architecture note.
- **Optional Local Spec**: `docs/plans/YYYY-MM-DD-<slug>/SPEC.md` (when present).

Extract core goals (`G-*`), explicit non-goals (`NG-*`), requirements (`REQ-*`),
and architectural invariants (`ADR-*`).

### Step 2: Model Work Hierarchy & Dependency DAG
1. **Structure the Tree**:
   - **Epic** (`templates/epic.md`): Container for initiative goals, non-goals,
     and exit criteria.
   - **Story / Sub-Issue** (`templates/story.md`): End-to-end vertical slice
     (`1.0–3.0 pt`).
   - **Task** (`templates/task.md`): Focused engineering step (`0.5–1.0 pt`)
     when a story requires separate PRs. Local `Plan:` trailers apply only
     when using the optional `docs/plans/` adapter; issue-first repos link
     with `Closes #N` or Jira keys.
2. **Wire Explicit Dependency Edges**: Record `Depends on #N` / `Blocked by #N`
   between downstream and upstream nodes.
3. **Verify Acyclicity & Compute Ready Frontier**: Run a cycle check (Kahn's
   algorithm / DFS). Identify the **ready frontier** (open nodes whose upstream
   dependencies are all complete) vs. **blocked chains** and the **critical path**.
4. **Map DAG to Branch Topology**:
   - **Trunk Streaming / Flat `epic/<id>`**: Independent frontier slices branch
     from `master` or `epic/<id>`.
   - **Stacked Branches**: Dependent slices branch from their upstream
     dependency branch and target that upstream PR base until it merges.

See `references/hierarchy-and-dependency-dags.md` for full DAG rules, worked
examples, cycle resolution, and branch-tree mapping.

### Step 3: Author Strict Acceptance Criteria (Given / When / Then)
Every Story and Task must specify unambiguous, testable criteria:
- **Given** [preconditions, setup state, or mock configuration],
- **When** [action, API request, or CLI invocation is executed],
- **Then** [verifiable system state, exit code, returned payload, or error message].

Include at least one Happy Path criterion and one Failure/Edge Case criterion.

### Step 4: Dry-Run Review
Present a preview table including hierarchy and dependency edges before writing
to external trackers:

```markdown
| ID / Key | Type | Title | Parent | Depends On | Sizing | Target Files |
|---|---|---|---|---|---|---|
| `#101` | Story | Add sandbox memory limit cgroup | `#100` | None (Ready) | 1.0 pt | `src/sandbox.c` |
| `#102` | Story | Add CLI flag `--max-memory` | `#100` | `#101` (Blocked) | 1.0 pt | `src/cli.c` |
```

### Step 5: Provision via Target Adapter (Optional)
Upon confirmation, export or create tickets using the repository's adapter:
- **GitHub Issues**: `github-issues` / `github-cli` (parent epic, native
  sub-issues, `Depends on #N` / `Blocked by #N` links).
- **Jira**: `jira-api` (Epic parent link and `Blocks` / `is blocked by` links).
- **Local Markdown (`docs/plans/`)**: Optional export to `SPEC.md` or backlog
  files when in-repo specs are used.

## 3. Sizing Calibration

| Points | Complexity | Effort | Uncertainty | Guideline |
|---|---|---|---|---|
| **0.5 pt** | Low | Small | Low | Trivial config or isolated one-line fix. |
| **1.0 pt** | Low–Med | Small–Med | Low | Standard single-PR vertical slice. |
| **2.0 pt** | Medium | Medium | Low–Med | Multi-file vertical slice with unit tests. |
| **3.0 pt** | Med–High | Med–High | Low | Maximum permissible size for a single ticket. |
| **$\ge$ 5.0 pt** | High | Large | High | **Must be split** before implementation. |

## 4. Templates & References

- **Templates**:
  - `templates/epic.md` — Epic container with goals, non-goals, hierarchy, and DAG table.
  - `templates/story.md` — Vertically sliced story/sub-issue with Given/When/Then AC.
  - `templates/task.md` — Engineering task with explicit target files and evidence logging.
- **References**:
  - `references/hierarchy-and-dependency-dags.md` — Epic/sub-issue hierarchies, dependency DAGs, ready frontiers, cycle detection, and branch-tree mapping.
  - `references/ticket-authoring-guide.md` — Slicing heuristics, 3-factor sizing, AC patterns, and traceability linkage.
