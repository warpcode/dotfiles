# Technical Task Decomposition & Estimation

Guidelines for breaking down user stories into decoupled technical subtasks with story point estimates.

---

## 1. Estimation Calibration Scale

Use a standardized effort & risk scale:

| Points | Complexity & Scope | Typical Duration |
|---|---|---|
| **0.5** | Minor tweak, copy change, configuration flag, simple test addition. | < 2 hours |
| **1.0** | Single-component change with clear patterns (e.g. single endpoint or UI form). | Half day |
| **2.0** | Full vertical slice across DB, Backend, and Frontend. | 1 day |
| **3.0** | Complex feature involving multi-step business logic, third-party integrations, or async jobs. | 2–3 days |
| **5.0** | High-risk architectural change; MUST be broken down into smaller stories. | > 1 week |

---

## 2. Decoupling Subtasks

When breaking down a story, separate into independent, parallelizable work units:

1. **Schema & Migration (`[DB]`)**:
   - Migration file, database indexes, table constraints.
2. **Backend Services & API (`[BE]`)**:
   - DTOs / Form Request validation, Service class, API Controller, unit/integration tests.
3. **Frontend UI & State (`[FE]`)**:
   - Component markup/styling, state store actions, API client methods, form validation.
4. **End-to-End Testing & Verification (`[QA]`)**:
   - Integration tests, seed data, manual regression checks.

