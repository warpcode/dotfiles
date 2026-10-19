# Product Scope, Requirements (EARS / MoSCoW) & Non-Goals Guide

Guidelines for formulating Charter summaries, Goals (`G-*`), Non-Goals (`NG-*`), and Requirements (`REQ-*`) in `SPEC.md`.

---

## 1. Problem Framing & Explicit Non-Goals (`NG-*`)

Every project and sub-project must lock its negative boundaries before adding features:
- **Goals (`G-*`)**: Measurable user or engineering outcomes unlocked by the scope.
- **Non-Goals (`NG-*`)**: Features, integrations, or behaviors **deliberately excluded** from scope.
  - Non-Goals are inherited by every plan under `features/`. A feature must also add at least one feature-specific `NG-*`.
  - During the Workflow B scrutiny check, any proposal that violates an inherited `NG-*` must be flagged immediately. It is then either rejected (a `REJ-*` entry with **Conflicts With** `NG-xxx`) or the Non-Goal itself is formally superseded, with user approval.

---

## 2. Normative Requirements Syntax (RFC 2119 & EARS)

When recording `--kind REQ`, use unambiguous EARS patterns with normative keywords (`MUST`, `SHALL`, `SHOULD`, `MUST NOT`):

1. **Ubiquitous (Always Active)**:
   `The <component> SHALL <behavior>.`
2. **Event-Driven (Triggered)**:
   `WHEN <trigger event>, the <component> SHALL <response>.`
3. **State-Driven (While in Condition)**:
   `WHILE <in state>, the <component> SHALL <behavior>.`
4. **Unwanted Behavior (Guardrail / Fault)**:
   `IF <fault or invalid input>, THEN the <component> SHALL <fail-safe action>.`

---

## 3. MoSCoW Prioritization in `REQ-*` Titles or Statements

Tag requirements by delivery criticality:
- **`[Must Have / P0]`**: Non-negotiable minimum viable core required for milestone exit.
- **`[Should Have / P1]`**: High-value capability with a viable short-term workaround.
- **`[Could Have / P2]`**: Desirable enhancement; first to be cut under schedule pressure.
- **`[Won't Have]`**: Record as `NG-*` (Non-Goal) rather than an active requirement.
