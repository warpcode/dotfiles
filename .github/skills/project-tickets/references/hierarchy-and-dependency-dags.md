# Work Hierarchy, Dependency DAGs & Branch Topology

Guide for modeling hierarchical work items (Epics, Sub-Issues, Tasks), explicit dependency DAGs, topological readiness, cycle detection, and branch-tree mapping without requiring local `docs/plans/` specifications.

---

## 1. Work Hierarchy (Parent–Child Containment)

Model work as a strict tree of containment:

```text
Initiative / Epic
├── Sub-Issue / Story A
│   ├── Task A.1 (optional)
│   └── Task A.2 (optional)
└── Sub-Issue / Story B
```

### Tracker Mappings

| Canonical Level | GitHub Issues | Jira | Local `docs/plans/` (Optional) |
|---|---|---|---|
| **Initiative / Epic** | Parent tracking issue (`epic` label) + native sub-issues or `- [ ] #N` tasklist | `Epic` issue type (`parent` field on children) | `SPEC.md` (`G-*`, `M-*`) |
| **Sub-Issue / Story** | Native sub-issue linked to parent Epic (`<= 3.0 pt`) | `Story` or `Task` with `parent = EPIC-KEY` | `REQ-*` / `TSK-*` |
| **Sub-Task / Task** | Child sub-issue when a story needs split PRs (`<= 3.0 pt`) | `Sub-task` with `parent = STORY-KEY` | `TSK-*` |

**Hierarchy vs. Dependency Invariant**: Containment (`Parent` / `Sub-issue`) expresses scope aggregation ("Epic completes when all children complete"). Execution ordering is expressed exclusively by dependency edges (`Depends on` / `Blocked by`). Never overload parent-child links to mean execution order, and never treat a dependency link as parent containment.

---

## 2. Dependency DAG Semantics

Execution ordering forms a **Directed Acyclic Graph (DAG)** across sibling or cross-epic work items:

- **Edge Direction**: `B` `Depends on #A` / `Blocked by #A` (equivalently `A` `Blocks #B`) means `A` is **upstream** (prerequisite) and `B` is **downstream** (dependent).
- **Tracker Representations**:
  - **GitHub**: Native issue dependency links (`blocked_by` / `blocking`) or explicit body lines `Depends on #N` / `Blocked by #N`.
  - **Jira**: Issue link type `Blocks` / `is blocked by`.
  - **Local Spec**: `Depends On:` field on `TSK-*` / `REQ-*`.
- **Cross-Epic Edges**: Allowed when a downstream slice depends on a shared foundation in another epic, provided no cycle is created and the upstream epic owns delivery of the prerequisite.

---

## 3. Topological Readiness & Critical Path

Evaluate readiness strictly from the DAG state (never by issue number order):

| State | Topological Condition | Action |
|---|---|---|
| **Ready Frontier** | Open node whose upstream `Depends on` / `Blocked by` targets are **all `DONE`** (closed with merged code, not merely drafted) | Eligible for immediate implementation |
| **Blocked Chain** | Open node with at least one upstream dependency still `OPEN`, `IN_PROGRESS`, or `BLOCKED` | Hold implementation or stack on upstream branch only if explicitly stacked |
| **Critical Path** | Longest weighted chain (by points or serial depth) of unresolved dependency edges from an open frontier node to the epic exit | Prioritize frontier nodes on this path first |

### Worked Example

Consider Epic `#100` with four sub-issues:

| Issue | Size | Depends On | Upstream Status | Classification | Branch Base |
|---|---|---|---|---|---|
| `#101` Schema migration | 1.0 pt | None | — | **Ready Frontier** (Critical Path) | `epic/100` or `master` |
| `#102` Auth provider config | 1.0 pt | None | — | **Ready Frontier** | `epic/100` or `master` |
| `#103` Service endpoint | 2.0 pt | `Depends on #101` | `#101` Open | **Blocked** (unblocked once `#101` merges) | Stack on `#101` branch (or wait) |
| `#104` CLI integration | 1.0 pt | `Blocked by #102, #103` | `#102` Open, `#103` Open | **Blocked** (Critical Path tail) | Stack on `#103` branch (or wait) |

Critical path: `#101 -> #103 -> #104` (4.0 pt serial depth). `#101` and `#102` form the initial **ready frontier** and can proceed in parallel.

---

## 4. Cycle Detection & Edge Hygiene

A valid work graph MUST be acyclic. Before finalizing a decomposition or starting work, verify the graph has zero cycles:

### Detection Methods
1. **Kahn's Algorithm (Indegree Peeling)**: Repeatedly remove nodes with `in-degree == 0` (no remaining unvisited upstream dependencies) and decrement downstream in-degrees. If any nodes remain when no zero-in-degree node exists, those remaining nodes participate in or sit downstream of a cycle.
2. **DFS Three-Color Check**: Traverse edges `downstream -> upstream` (or `upstream -> downstream`) marking nodes `Unvisited`, `Visiting` (on current recursion stack), and `Visited`. Reaching a `Visiting` node indicates a back-edge cycle.

### Mandatory Edge Hygiene Rules
- **Self-Loops**: Reject `A Depends on A`.
- **Mutual Cycles**: Reject `A Depends on B` + `B Depends on A`. Extract the shared contract into a thin `0.5–1.0 pt` prerequisite node `C` so both `A` and `B` depend on `C`.
- **Transitive Cycles**: Reject `A -> B -> C -> A` by re-slicing the boundary where the circular interface occurs.
- **Closed-as-Not-Planned / Won't-Do Upstreams**: Never leave an active node blocked on a `Closed (Not Planned)` or `Won't Do` issue. Either remove the dependency edge, re-scope the node, or close the downstream node as obsolete.

---

## 5. Mapping DAG Structure to Branch & PR Topology

Select the branch strategy directly from the DAG shape:

```text
Independent Frontier (parallel)         Dependent Chain (stacked)
master / epic/100                       master / epic/100
├── feat/101-schema                     └── feat/101-schema (PR -> master or epic/100)
└── feat/102-auth                           └── feat/103-endpoint (PR -> feat/101-schema)
                                                └── feat/104-cli (PR -> feat/103-endpoint)
```

| DAG Shape | Recommended Strategy | Branch & PR Rules |
|---|---|---|
| **Wide / Independent Ready Frontier** | **Trunk Streaming** (or flat `epic/<id>` fan-out) | Branch each ready sub-issue directly from `master` (or `epic/<id>` integration branch). Use feature flags if partial increments must remain inactive behind trunk. |
| **Deep Serial Chains (`A -> B -> C`)** | **Stacked Branches** | Branch `B` from `A`'s head branch; set `B`'s PR base to `A`'s branch (never `master`) until `A` merges. Retarget `B`'s PR base to `master` (or `epic/<id>`) once `A` lands. |
| **Multi-Slice Epic with Shared Integration** | **Epic-Tree Branch** (`epic/<id>`) | Independent children branch from and PR into `epic/<id>`; dependent children stack on their upstream branch. Merge `epic/<id>` to `master` when exit criteria pass. |

For branch creation, conflict sync, and stacked-PR retargeting mechanics, load `git-expert` and `github-pr`.

---

## 6. DAG Anti-Patterns

- **Hidden Dependencies**: Implementing `B` against unmerged assumptions from `A` without recording `Depends on #A` (causes silent sequencing breaches and merge conflicts).
- **Fan-In Bottlenecks**: One giant `5.0+ pt` integration ticket blocking 6 downstream items. Split the shared interface out first (`<= 1.0 pt`) to widen the ready frontier.
- **Oversized Nodes (`> 3.0 pt`)**: Large multi-day nodes hide serial sub-steps inside a single ticket. Decompose into smaller vertical slices with explicit edges.
- **Horizontal-Layer Dependencies**: `All DB -> All API -> All UI` chains force artificial serialization. Re-slice vertically so multiple end-to-end capabilities sit in the ready frontier simultaneously.
