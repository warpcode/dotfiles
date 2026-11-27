---
name: ai-conversation-review
description: >
  Audit a human-AI conversation transcript to progressively improve agents, skills and instructions.
  Measures how much of the session's tool work could be offloaded into scripts, finds repeated tool
  sequences, retry loops, context-heavy outputs, missed skills and guideline violations, then proposes
  concrete diffs. Use when the user says "review this conversation", "audit our session", "analyse chat
  history", "run conversation review", "why did the agent take so long" or "improve this skill/agent".
---

# AI Conversation Review

Turn a finished session into measurable improvements for skills, agents, and instructions. **Scripts gather and count; the model only judges.**

`<skill-dir>` = the directory containing this file. Always invoke scripts by that path; never assume the working directory.

## Stage 1: Gather Audit Dossier (Budget: <=3 Tool Calls)

Always pass an explicit conversation UUID, session ID (`ses_...`), or transcript path. Never default to `--latest` when reviewing an active session — `--latest` picks the newest transcript machine-wide across all workspaces and concurrent sessions.

| Platform | Target Argument |
|---|---|
| Copilot Chat / Claude Code / Markdown | Session UUID or transcript file path |
| Google Antigravity / Gemini CLI | Conversation UUID |
| OpenCode | Session ID (`ses_...`, read-only SQLite) |

```bash
# Unified dossier (metrics, offload candidates, smells, user corrections, history baseline):
python3 <skill-dir>/scripts/review_conversation.py <uuid_or_path_or_ses_id> --record

# Diagnostic modes (use instead of ad-hoc scripts):
python3 <skill-dir>/scripts/review_conversation.py <target> --sizes          # byte breakdown & context hogs
python3 <skill-dir>/scripts/review_conversation.py <target> --schema         # transcript schema keys
python3 <skill-dir>/scripts/review_conversation.py <target> --segment final  # or turn:N / start:end
python3 <skill-dir>/scripts/review_conversation.py <target> --user-turns     # chronological user timeline

# Cross-session empirical tool & script audit (default 200 sessions):
python3 <skill-dir>/scripts/search_tools.py --scripts-dir <target-skill>/scripts/ [--sessions 200] [--json]
```

| Supporting Script | Purpose |
|---|---|
| `@scripts/parse_conversation.py` | Multi-platform transcript parser (Antigravity, VS Code, OpenCode, Claude Code) |
| `@scripts/offload_analysis.py` | Detector for tool sequences, retry loops, and script offload candidates |
| `@scripts/export_opencode_session.py` | Dump OpenCode SQLite sessions to portable JSONL |
| `@scripts/audit_vscode_session.py` | Structural auditor for VS Code Copilot Chat session records |

**Prohibitions:** Never write inline `python3 -c` / heredocs, chain multi-pipe shell filters, or dump raw transcripts into context.

## Stage 2: Offload & Efficiency Assessment

Classify every script candidate from the dossier (`@references/script-consolidation-guide.md`):

| Class | Rule | Action |
|---|---|---|
| **Script** | Deterministic inputs; steps never branch on meaning | Bundle in `<skill>/scripts/`, document in `SKILL.md` |
| **Script + flags** | Branches on simple conditions (exists, exit code, regex) | Parameterize with explicit flags |
| **Keep in model** | Depends on interpreting semantics, tone, or architecture | Keep in model; script only data gathering in front of it |

**Efficiency & script standards:** Flag N+1 sequential request loops (require batch/bulk endpoints), uncached immutable queries, and client-side filtering that belongs at the API boundary. Proposed scripts must expose `--help`, stay non-interactive, emit concise Markdown (plus `--json`), fail loudly, and support `--dry-run` on mutations. Start shell helpers from `templates/script-wrapper-blueprint.sh`.

## Stage 3: Guideline, Skill & Durable Learning Audit

1. **Compliance**: Check active rules (`AGENTS.md`, `.github/copilot-instructions.md`, `*.instructions.md`, loaded `SKILL.md`) for checkable rules only; mark **Kept / Broken / N/A** with User Turn # (Event #) evidence.
2. **Skills**: Audit whether bundled scripts were used or bypassed, diagnose missed triggers (frontmatter `description`), and check granularity via `@references/prompt-and-skill-audit-rubric.md`.
3. **Durable Learnings**: Extract recurring user corrections and settled decisions with Turn # quotes; deduplicate against `@references/memory-and-instruction-hierarchy.md`.

## Stage 4: Route Fixes to the Right Architectural Layer

Scope first (project fixes in project files; universal fixes in global config), then route each finding to its owning layer — **never route agent fixes to `.github/workflows/` and never append dated war stories to `SKILL.md`**:

| Finding Type | Target Layer | Rule |
|---|---|---|
| Timeless API, CLI, or tool gotchas | Domain skill `@references/` (`<skill>/references/*.md`) | Distill cause and fix; omit dates and session narratives |
| Repeated multi-call shell sequences, loops, or N+1 queries | Domain skill `@scripts/` (`<skill>/scripts/*`) | Single bundled script + routing row in `SKILL.md` |
| Workflow orchestration, step ordering, or role persona | `.github/agents/*.agent.md` or `.github/prompts/*.prompt.md` | Keep `SKILL.md` focused on domain knowledge |
| Universal defaults, coding conventions, or safety invariants | `AGENTS.md` or `*.instructions.md` | Path-scoped rules for file globs; root `AGENTS.md` only for repo-wide rules |

## Stage 5: Compact Report

Use `templates/conversation-review-report.md` (omit metadata headers and unrequested compliance tables; no praise, no narrative recap, no findings without turn evidence):
1. **Script candidates**: sequence replaced, calls saved, suggested script, target skill.
2. **Suggestions / Advice**: one line each with priority (`High`/`Medium`/`Low`) and Turn # evidence.
3. **Improvements**: concrete diffs per target file routed per Stage 4.
