#!/usr/bin/env python3
"""offload_analysis.py - Estimate how much of a session's tool work could be offloaded into scripts.

Reads any transcript supported by parse_conversation.py and reports, as compact Markdown:
  - Mechanical chains: consecutive tool calls with no assistant reasoning or user turn between them.
  - Repeated sequences: tool-call n-grams that recur (candidates for one parameterised script).
  - Retry loops: a call that failed and was immediately retried with the same tool/command.
  - Offload estimate: share of tool calls covered by the above, and projected call count after scripting.
  - Output cost: tools ranked by result size (only when the parser supplies result_chars).

The model should only decide WHICH candidates are worth scripting; all detection and counting is done here.

Usage:
  offload_analysis.py <transcript> [--min-repeat N] [--max-n N] [--top N] [--json]

Exit codes: 0 success, 1 input error.
"""
import argparse
import json
import shlex
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from parse_conversation import ingest_transcript  # noqa: E402

SHELL_TOOLS = {"run_in_terminal", "bash", "Bash", "shell", "execute_command", "bash_tool", "terminal"}


def tool_key(call):
    """Normalise a call to a stable key. Shell calls become sh:<cmd> or sh:git <sub>."""
    name = call.get("name", "tool")
    if name not in SHELL_TOOLS:
        return name
    args = call.get("args") or call.get("arguments") or {}
    cmd = args.get("command", "") if isinstance(args, dict) else str(args)
    try:
        words = [w for w in shlex.split(cmd) if "=" not in w.split("/")[0]]
    except ValueError:
        words = cmd.split()
    if not words:
        return "sh:?"
    head = Path(words[0]).name
    if head in {"git", "gh", "docker", "kubectl", "az", "npm", "composer"} and len(words) > 1:
        return f"sh:{head} {words[1]}"
    if head.startswith("python") and len(words) > 1 and words[1].endswith(".py"):
        return f"sh:{Path(words[1]).name}"
    return f"sh:{head}"


def build_steps(events):
    """Flatten events into tool steps, tagging where reasoning/user turns break a chain."""
    steps, segment, broken = [], 0, True
    for ev in events:
        role = ev.get("role")
        calls = ev.get("tool_calls") or []
        if role == "user":
            segment += 1
            broken = True
            continue
        if role == "assistant" and (ev.get("content") or "").strip() and not calls:
            broken = True
            continue
        for call in calls:
            steps.append({
                "key": tool_key(call),
                "failed": call.get("status") in ("failed", "error"),
                "chars": call.get("result_chars"),
                "segment": segment,
                "chain_start": broken,
            })
            broken = False
    return steps


def find_chains(steps):
    chains, current = [], []
    for i, s in enumerate(steps):
        if s["chain_start"] and current:
            chains.append(current)
            current = []
        current.append(i)
    if current:
        chains.append(current)
    return [c for c in chains if len(c) >= 2]


def find_sequences(steps, max_n, min_repeat):
    """Count n-grams within user segments; drop ones fully explained by a longer kept n-gram."""
    found = {}
    for n in range(max_n, 1, -1):
        grams = Counter()
        where = {}
        for i in range(len(steps) - n + 1):
            window = steps[i:i + n]
            if len({s["segment"] for s in window}) != 1:
                continue
            key = tuple(s["key"] for s in window)
            if len(set(key)) == 1:
                continue  # pure repeats are reported as retries/duplicates, not sequences
            grams[key] += 1
            where.setdefault(key, []).append(i)
        for key, count in grams.items():
            if count < min_repeat:
                continue
            subsumed = any(count <= c and _contains(longer, key) for longer, (c, _) in found.items())
            if not subsumed:
                found[key] = (count, where[key])
    return found


def _contains(longer, shorter):
    n = len(shorter)
    return any(longer[i:i + n] == shorter for i in range(len(longer) - n + 1))


def find_retries(steps):
    return [i for i in range(1, len(steps))
            if steps[i - 1]["failed"] and steps[i]["key"] == steps[i - 1]["key"]]


def script_name(seq):
    parts = [k.replace("sh:", "").replace(" ", "-").split("_")[0] for k in seq]
    return "_".join(dict.fromkeys(parts))[:40] + ".py"


def classify_candidate(seq):
    is_all_shell = all(k.startswith("sh:") for k in seq)
    has_git = any("git" in k for k in seq)
    has_reads = any(k in ("read_file", "view_file") for k in seq)
    if is_all_shell or (has_git and not has_reads):
        return "Script"
    return "Script + flags"


def analyse(steps, max_n, min_repeat, top):
    total = len(steps)
    chains = find_chains(steps)
    seqs = find_sequences(steps, max_n, min_repeat)
    retries = find_retries(steps)

    covered = set(retries)
    for c in chains:
        covered.update(c)
    for key, (_, starts) in seqs.items():
        for s in starts:
            covered.update(range(s, s + len(key)))

    in_chain = {i for c in chains for i in c}
    saved_chains = sum(len(c) - 1 for c in chains)
    saved_retries = sum(1 for i in retries if i not in in_chain)  # chain savings already cover in-chain retries
    saved = min(max(total - 1, 0), saved_chains + saved_retries)

    candidates = sorted(
        ({"sequence": list(k), "occurrences": c, "calls_saved": (len(k) - 1) * c, "class": classify_candidate(k), "suggested_script": script_name(k)}
         for k, (c, _) in seqs.items()),
        key=lambda x: -x["calls_saved"],
    )[:top]

    sizes = Counter()
    counts = Counter()
    for s in steps:
        if isinstance(s["chars"], int):
            sizes[s["key"]] += s["chars"]
            counts[s["key"]] += 1

    return {
        "tool_calls": total,
        "mechanical_chains": len(chains),
        "calls_in_chains": sum(len(c) for c in chains),
        "repeated_sequences": len(seqs),
        "retry_loops": len(retries),
        "offloadable_share": round(len(covered) / total, 2) if total else 0.0,
        "projected_calls_after_scripting": total - saved,
        "candidates": candidates,
        "output_cost": [{"tool": k, "calls": counts[k], "result_chars": v, "avg_chars": v // counts[k]}
                        for k, v in sizes.most_common(top)],
    }


def render(r):
    out = ["# Offload Analysis", "",
           "| Metric | Value |", "| --- | ---: |",
           f"| Tool calls | {r['tool_calls']} |",
           f"| Mechanical chains (no reasoning between calls) | {r['mechanical_chains']} ({r['calls_in_chains']} calls) |",
           f"| Repeated sequences | {r['repeated_sequences']} |",
           f"| Retry loops | {r['retry_loops']} |",
           f"| **Offloadable share (estimate)** | **{int(r['offloadable_share'] * 100)}%** |",
           f"| **Projected calls after scripting** | **{r['projected_calls_after_scripting']}** |", ""]
    out += ["## Script Candidates", ""]
    if r["candidates"]:
        out += ["| Sequence | Seen | Calls saved | Class | Suggested script |", "| --- | ---: | ---: | --- | --- |"]
        out += [f"| `{' → '.join(c['sequence'])}` | {c['occurrences']} | {c['calls_saved']} | **{c.get('class', 'Script')}** | `{c['suggested_script']}` |"
                for c in r["candidates"]]
    else:
        out.append("- None above threshold")
    out += ["", "## Output Cost", ""]
    if r["output_cost"]:
        out += ["| Tool | Calls | Total chars | Avg chars |", "| --- | ---: | ---: | ---: |"]
        out += [f"| `{o['tool']}` | {o['calls']} | {o['result_chars']} | {o['avg_chars']} |" for o in r["output_cost"]]
    else:
        out.append("- Not available for this transcript format")
    return "\n".join(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("transcript", help="Transcript path, or - for stdin")
    p.add_argument("--min-repeat", type=int, default=2, help="Min occurrences for a sequence (default: 2)")
    p.add_argument("--max-n", type=int, default=4, help="Longest sequence length to detect (default: 4)")
    p.add_argument("--top", type=int, default=8, help="Rows per table (default: 8)")
    p.add_argument("--json", action="store_true", help="Emit one JSON line (for review-history.jsonl)")
    p.add_argument("--record", action="store_true", help="Append JSON line directly to review-history.jsonl")
    a = p.parse_args()

    session_id = "stdin"
    tpath_str = "-"
    if a.transcript == "-":
        raw = sys.stdin.read()
    else:
        path = Path(a.transcript)
        if not path.is_file():
            print(f"Error: transcript not found: {path}", file=sys.stderr)
            sys.exit(1)
        raw = path.read_text(encoding="utf-8", errors="replace")
        session_id = path.stem
        tpath_str = str(path)

    result = analyse(build_steps(ingest_transcript(raw)), a.max_n, a.min_repeat, a.top)
    result["session_id"] = session_id
    result["transcript_path"] = tpath_str

    if a.record:
        import tempfile
        hist_dir = Path(tempfile.gettempdir()) / "ai-conversation-review"
        hist_dir.mkdir(parents=True, exist_ok=True)
        hist_path = hist_dir / "review-history.jsonl"
        with hist_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(result, separators=(",", ":")) + "\n")

    if a.json:
        print(json.dumps(result, separators=(",", ":")))
    elif not a.record:
        print(render(result))


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
