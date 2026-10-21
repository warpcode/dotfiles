# [ARCHETYPE: Feature | Refactor | Bug | Spike | Security]: [Descriptive Title]

- **Task ID**: `TSK-xxx` | **Scope**: `<project>[/<subproject>]`
- **Fulfills Requirement(s)**: `REQ-xxx` *(Mandatory upstream requirement link)*
- **Governed By Decision(s)**: `ADR-xxx`, `DT-xxx`
- **3-Factor Estimate**: `[0.5 | 1.0 | 2.0 | 3.0 pt]` *(Complexity: Low/Med/High, Effort: S/M/L, Uncertainty: Low/Med/High)*
- **Git Trailer**: `Plan: <slug>:TSK-xxx`
- **Evidence**: PR <link/number> · Commit <sha> · Ticket <id>

## 1. Context & Problem Statement
[Self-contained background, user story, or defect reproduction steps. Zero tacit memory dependency.]

## 2. Technical Specification & Explicit File Targets
- **Target Files**: `path/to/file.py`, `path/to/test_file.py`
- **Contracts / Schemas**: Request/Response JSON, CLI signature, or state schema
- **Error & Boundary Conditions**: Exact error codes and edge-case handling

## 3. Acceptance Criteria (Deterministic)
- [ ] **AC 1**: Given `<initial state>`, when `<action>`, then `<verifiable outcome>`.
- [ ] **AC 2**: Given `<invalid input or boundary>`, when `<action>`, then `<exact error/fallback>`.

## 4. Subtask Layer Decomposition
- [ ] **[CORE / BE]**: Domain logic and interface implementation
- [ ] **[DOCS]**: Spec, ADR, or documentation update
- [ ] **[QA]**: Automated unit/integration regression tests (`./validate.sh`)
