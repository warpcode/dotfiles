---
name: jules-agent-prompts
description: Write, improve, review or extend prompts for Google Jules scheduled/async coding agents (Bolt performance, Sentinel security, Palette, documentation auditors, test writers, CI/workflow auditors, etc.) and any unattended agent that opens GitHub PRs on a schedule. Use this whenever the user mentions Jules, scheduled Jules tasks, "Bolt", "Sentinel", maintenance/janitor agents for GitHub repos, agents that create duplicate PRs, miss issues, are pedantic or micro-optimise, or asks for new agent ideas for repositories, even if they don't say "skill" or "prompt".
---

# Jules agent prompts

Produce prompts for unattended repo-maintenance agents that run in Google Jules. A scheduled run is a fresh VM with no memory, nobody to answer questions, and a very limited view of GitHub. Prompts that ignore this produce duplicate PRs, trivial changes and noise, so most of this skill is about designing for that environment.

## Environment facts (treat as hard constraints)

- Jules' git is a LOCAL clone: no remotes, no `gh`, no GitHub API, no view of open PRs, closed PRs or issues. Jules' own integration creates branches, pushes and opens PRs. Never tell an agent to fetch, push, use `gh`/`curl`, read PR refs, look up issues, name branches, apply labels, or open PRs by hand.
- Scheduled tasks cannot be edited after creation, and prompts cannot include or share each other. Every prompt must be fully standalone (protocol inlined). Tell the user to delete and recreate tasks when prompts change.
- Runs are unattended. "Ask first" cannot work, so convert it to: don't do it, list it as a recommendation in the final message.
- The clone may be shallow, so history checks can be limited. The agent should say so and be more conservative.
- Details I could not verify: Jules' prompt length limit and daily task quota (last seen about 15/day, 3 concurrent; check current docs). Flag these when relevant; never present them as fact.

## Design rules (the user rejected the opposite more than once)

1. **No repo litter.** A PR contains only the fix and its tests. Never have an agent create or modify a `.jules/` directory (it must never exist), journals, ledgers, state files, fingerprints, signatures, tags, ID strings, or any housekeeping file. Lessons, near misses and recommendations go in the final message only. Do not propose companion automation (Actions that maintain state, etc.) unless asked.
2. **Don't invent machinery.** Add only what fixes a problem the user stated. If you think a mechanism would help, say so in one sentence in your reply as an option instead of putting it in the prompt. Prior over-engineering cost trust.
3. **Dedupe honestly with what is visible:** code, git history (`git log -S`, recent commits, reverts), an optional human-maintained ignore list the user creates themselves, and a weekly focus slice (different top-level directory per run) to spread agents out. The agent must say in the PR that open and rejected PRs could not be checked, and must never claim it checked them. Warn the user that occasional duplicates remain possible and that schedules should be slower than their review cycle.
4. **Quality gates beat volume.** No PR is a successful run. Every agent needs an evidence requirement, an impact threshold, a "do not ship" list, and a final-message "near misses" list. This is what fixes pedantry, over-zealous changes and micro-optimisation.
5. **Stack-agnostic discovery.** Agents must detect the repo's real commands from AGENTS.md, README and CI files and run a baseline first. Never hardcode pnpm, React, TypeScript, or `{{PLACEHOLDER}}` values that Jules won't fill in.
6. **Verify honestly.** Never claim tests pass unless run. Prefer a test that fails before and passes after.

## Workflow

1. Identify what the user wants: improve an existing prompt, write a prompt for a listed agent, or invent a new agent.
2. Read `references/protocol.md` (shared protocol, already encodes the rules above).
3. For known agents read `references/agents/<name>.md`. Available: bolt, sentinel, docs-auditor, test-smith, workflow-warden, ratchet, flake-hunter, release-scribe. For an existing user prompt, diagnose it against the failure list below, then rewrite it in the same agent-block style.
4. For a new agent, write an agent block with: mission, how to choose a target, evidence requirement, threshold, do-not-ship list, final message. Keep it short; the protocol carries everything shared. Add an agent offset in the focus-slice line of the protocol if you add an agent (next unused integer).
5. Build standalone files: `python scripts/build_prompts.py <out_dir> [agent ...]` concatenates agent block + protocol into one `.txt` per agent. Present the files, one per Jules task.
6. In the reply, state what changed and why, list anything unverified, and keep it short.

## Failure list for diagnosing existing prompts

- Duplicates: no dedupe at all, or dedupe that needs GitHub access Jules lacks.
- Misses: random scanning; hard cap of ~50 lines; no data-flow/entry-point ordering.
- Pedantry and micro-optimisation: no evidence bar or impact threshold; "find something every run"; PR-or-bust framing.
- Environment mismatches: `gh`, remotes, branch names, labels, journals in `.jules/`, unresolved placeholders, "ask first" in unattended runs, assumed toolchain.
- Docs auditors: auditing every claim in the repo instead of prioritising reader-blocking docs (setup steps, env vars, API contracts, dead references) and recently changed code.
- Security agents: flagging unreachable or framework-handled issues; leaking exploit details or secrets into PR text of public repos.

## New agent ideas to offer

Test writer with a break-the-code sanity check, GitHub Actions auditor, static-analysis/deprecation ratchet using the repo's own tools, flaky test reproducer (local repeated runs only), changelog writer from git log, container/Kubernetes hygiene, UX/accessibility (Palette). Offer only when the user asks for more agents.
