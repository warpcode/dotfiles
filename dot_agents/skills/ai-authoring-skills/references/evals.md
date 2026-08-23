# Running skill evals with subagents

Read this when the user wants empirical proof a skill works: test prompts,
graded runs, pass rates, or trigger benchmarks. It uses each platform's
native subagent spawning, so the same procedure works on Copilot/VS Code,
OpenCode, Cursor, Gemini CLI/Antigravity, Hermes Agent, and any other agent
host with dynamic subagents.

## Core loop

- Figure out where the user is: new skill, draft already written, or
  improving an existing one. Jump in at that stage.
- Draft or edit the skill.
- Run test prompts through independent subagents - with the skill and
  without it (or against the old version).
- Grade outputs against assertions; aggregate a benchmark.
- Review results with the user; improve the skill from their feedback plus
  any glaring quantitative flaws.
- Repeat until the user is satisfied, then optionally optimize the
  description for triggering.

Flexibility rule: if the user says "just vibe with me", skip the harness and
review qualitatively.

## Layout and schemas

Test cases live inside the skill package; run artifacts live in a workspace
sibling to the skill directory. Create directories as you go - never upfront.

```
<skill-name>/
└── evals/
    └── evals.json            # test cases + assertions
<skill-name>-workspace/       # sibling of the skill directory
├── skill-snapshot/           # copy of the OLD skill when improving (baseline)
└── iteration-N/
    ├── eval-<ID>-<descriptive-name>/
    │   ├── eval_metadata.json
    │   ├── with_skill/outputs/
    │   ├── with_skill/timing.json
    │   ├── without_skill/    # or old_skill/ - see Step 2
    │   └── without_skill/timing.json
    ├── benchmark.json
    └── feedback.json
```

`evals/evals.json`:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 0,
      "name": "parse-quarterly-csv",
      "prompt": "The user's task prompt",
      "expected_output": "Description of the expected result",
      "files": [],
      "assertions": []
    }
  ]
}
```

`eval_metadata.json` (one per eval directory, per iteration):

```json
{
  "eval_id": 0,
  "eval_name": "parse-quarterly-csv",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

`timing.json` (one per run directory):

```json
{"total_tokens": 84852, "duration_ms": 23332, "total_duration_seconds": 23.3}
```

`grading.json` (one per run directory). Field names are fixed - graders and
any aggregation code depend on `text` / `passed` / `evidence` exactly:

```json
{
  "run_id": "eval-0-parse-quarterly-csv-with_skill",
  "expectations": [
    {"text": "Output CSV has a profit_margin column",
     "passed": true,
     "evidence": "header row reads: region,revenue,cost,profit_margin"}
  ]
}
```

`benchmark.json`:

```json
{
  "skill_name": "example-skill",
  "iteration": 1,
  "configurations": [
    {"name": "with_skill",    "pass_rate": 0.83, "mean_tokens": 61000, "stddev_tokens": 4200, "mean_seconds": 41.2},
    {"name": "without_skill", "pass_rate": 0.50, "mean_tokens": 58000, "stddev_tokens": 3900, "mean_seconds": 38.7}
  ],
  "delta_pass_rate": 0.33
}
```

## Test workflow

### Step 1 - Write test cases

- Write 2-3 realistic prompts - the kind a real user would type, with real
  file paths, column names, and backstory. Vague prompts ("format this data")
  prove nothing.
- Share them with the user before running: "Here are the test cases I plan
  to run - look right, or add more?"
- Save to `evals/evals.json`. Prompts only at this stage; assertions come in
  Step 3.
- Skills with subjective outputs (writing style, design) may not need test
  cases at all - say so and let the user decide.

### Step 2 - Spawn all runs in one turn

For every test case, spawn TWO subagents in the same turn: one with-skill,
one baseline. Launching everything at once matters - the runs finish around
the same time and baselines are never skipped because "it got late".

**With-skill run prompt:**

```text
Execute this task:
- Skill path: <path-to-skill>
- First read <skill-path>/SKILL.md and follow its instructions for the task.
- Task: <eval prompt>
- Input files: <eval files, or "none">
- Save outputs to: <workspace>/iteration-N/eval-<ID>-<name>/with_skill/outputs/
- Outputs to save: <what the user cares about>
Work independently. Do not search for other instructions.
```

**Baseline choice:**

- Creating a new skill: no skill at all. Same prompt, no skill path, save to
  `without_skill/`.
- Improving an existing skill: snapshot BEFORE editing
  (`cp -r <skill-path> <workspace>/skill-snapshot/`), point the baseline
  subagent at the snapshot, save to `old_skill/`.

**Writing an `eval_metadata.json`** for each test case belongs in this step
too (assertions empty for now). Use descriptive eval names - they appear in
the benchmark, so "parse-quarterly-csv" beats "eval-0".

### Step 3 - Draft assertions while runs execute

Use the waiting time; do not idle.

- Draft objectively verifiable assertions per test case and explain them to
  the user. Good ones read clearly at a glance: "output CSV has a
  profit_margin column", "script exits 0 on the sample input".
- Subjective skills (tone, aesthetics) get qualitative review instead - do
  not force assertions onto human-judgment calls.
- Update `evals/evals.json` and each `eval_metadata.json` once drafted.

### Step 4 - Capture timing data

Task-completion notifications carry `total_tokens` and `duration_ms`. Save
each to `timing.json` in that run's directory immediately - this data arrives
once and is not persisted anywhere else. Process notifications as they
arrive rather than batching them.

If the platform reports no token/duration metadata, omit `timing.json`;
the benchmark then covers pass rate only.

### Step 5 - Grade the runs

Once all runs finish:

- Programmatic assertions (file exists, JSON parses, exit code): write and
  run a throwaway script instead of eyeballing - faster and reusable across
  iterations.
- Judgment assertions: spawn one grader subagent per iteration (grade inline
  only when 1-2 runs total):

```text
You are a grader. Evaluate run outputs against assertions - nothing else.
- Assertions: <eval_metadata.json path>
- Output files: <run outputs dir>
- For each assertion record passed true/false with concrete evidence
  (quote the output, or name the file and line).
- Write grading.json into the run directory using EXACTLY these fields:
  {"run_id": "<eval-dir>-<variant>", "expectations":
   [{"text": "...", "passed": true, "evidence": "..."}]}
  (each expectation: text, passed, evidence - no other keys).
Do not rewrite or reinterpret assertions. Grade only what is present.
```

### Step 6 - Aggregate the benchmark

Compute per configuration (with_skill, without_skill/old_skill):

- `pass_rate` = passed assertions / total assertions
- `mean_tokens` / `stddev_tokens` and `mean_seconds` from `timing.json`

Write `benchmark.json` (schema above) and print a markdown table with
with_skill rows directly beside their baseline. A short Python snippet is
fine; keep it deterministic and rerun it verbatim each iteration.

Then do an analyst pass over per-eval results - aggregates hide patterns:

- Assertions that pass in BOTH configurations are non-discriminating; they
  measure the model, not the skill.
- High-variance evals are probably flaky prompts; tighten or drop them.
- Token/time regressions vs baseline mean the skill adds ceremony without
  value - candidates for trimming.

### Step 7 - Present results and read feedback

Present results in conversation:

- Per test case: prompt, then each variant's output (link file paths for
  artifacts the user must open).
- The benchmark table plus analyst observations.
- Ask for feedback per test case and record replies in
  `<workspace>/iteration-N/feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-parse-quarterly-csv-with_skill",
     "feedback": "chart is missing axis labels"}
  ],
  "status": "complete"
}
```

Empty feedback means "fine as is". Focus improvements where the user wrote
something specific.

### Step 8 - Iterate

1. Improve the skill. Generalize from feedback rather than patching the
   specific example - the skill must work for prompts nobody has typed yet.
   Explain why in instructions instead of stacking MUSTs.
2. Rerun ALL test cases into `iteration-<N+1>/`, baselines included.
   Creating a new skill: baseline stays `without_skill`. Improving: choose
   between the user's original version and the previous iteration.
3. Present again (Step 7); compare against the previous iteration.
4. Stop when: the user says done, feedback is all empty, or changes stop
   moving the numbers.

## Description (trigger) optimization

The description decides triggering; optimize it after the body is stable.
Subagents simulate the metadata-only view every agent sees.

1. **Generate ~20 queries**: half should-trigger, half near-miss negatives
   that share keywords but need something else. Realistic and specific -
   file paths, casual phrasing, typos. Save `eval_set.json`:
   `[{"query": "...", "should_trigger": true}]`
2. **Review with the user** - bad queries produce bad descriptions.
3. **Score by simulation**: split 60% train / 40% test. For each query,
   spawn 3 judge subagents that see ONLY candidate name+description pairs -
   the skill under test plus 2-4 real distractors from `~/.agents/skills/` -
   and the query:

   ```text
   A user query arrived. Available skills (metadata only):
   - <name>: <description>
   - ...
   Which skill(s) would you load for this query? Reply with names only,
   comma-separated, or "none".
   ```

   Majority vote names the skill = triggered. Score trigger rate on
   positives and false-positive rate on negatives.
4. **Propose improvements** from failures (near-misses that wrongly trigger,
   positives that miss), rescore, keep the best by TEST score - never train
   score. Cap at ~5 rounds or stop when scores plateau.
5. **Apply** the winner to frontmatter; show the user before/after with
   scores.

## Platform notes

- Subagent spawning differs per surface: Copilot custom agents /
  `runSubagent`, OpenCode Task/@agents, Gemini CLI and Antigravity agent
  invocation. Use whatever native mechanism exists.
- No subagent capability at all: run each test case sequentially yourself
  after reading the skill's SKILL.md, skipping baselines. Say plainly that
  this is weaker - you wrote the skill and you are running it, so independence
  is lost; human review compensates.
- Timing capture requires the platform to report task metrics; otherwise
  pass-rate-only benchmarks (see Step 4).

## What NOT to do

- Do not run with-skill runs first and baselines later - spawn both in the
  same turn or the comparison drifts.
- Do not grade your own outputs silently in place of user review; the human
  loop is the quality bar, benchmarks only support it.
- Do not invent custom HTML viewers or one-off dashboards; conversation +
  markdown tables are the deliverable.
- Do not tune descriptions against train scores; that overfits the eval set.
- Do not keep iterating past the point of movement - flat benchmarks mean
  stop and ask the user.
