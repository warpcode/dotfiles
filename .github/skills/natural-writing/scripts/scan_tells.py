#!/usr/bin/env python3
"""Heuristic scanner for common AI-writing tells.

Usage: scan_tells.py [file] [--json]   (reads stdin if no file)
Heuristic only: hits point at sentences to review, not proof of AI authorship.
"""
import json, re, sys

PATTERNS = {
    "vocabulary": [r"\bdelv(e|es|ing)\b", r"\btapestry\b", r"\btestament\b", r"\bpivotal\b",
        r"\bcrucial\b", r"\blandscape\b", r"\brealm\b", r"\bunderscor(e|es|ing)\b",
        r"\bshowcas(e|es|ing)\b", r"\bfoster(s|ing)?\b", r"\bgarner(s|ed)?\b",
        r"\bintricate\b", r"\binterplay\b", r"\bmultifaceted\b", r"\bseamless(ly)?\b",
        r"\brobust\b", r"\bboasts?\b", r"\bnavigat(e|ing) the\b", r"\bever-evolving\b",
        r"\bmoreover\b", r"\bfurthermore\b", r"\badditionally\b", r"\bnotably\b",
        r"\benduring\b", r"\bresonat(e|es)\b", r"\belevate[sd]?\b", r"\bbolster"],
    "copula_avoidance": [r"\bserves as\b", r"\bstands as\b", r"\bacts as a\b", r"\brepresents a\b"],
    "significance": [r"\b(plays?|playing) an? (vital|pivotal|key|crucial|significant) role\b",
        r"\bmarks? a (significant|major|pivotal) (milestone|shift|moment)\b",
        r"\bindelible\b", r"\blasting (impact|legacy)\b", r"\bbroader (trend|context)s?\b",
        r"\bevolving landscape\b", r"\bpoised to\b"],
    "promotional": [r"\bvibrant\b", r"\bnestled\b", r"\bbustling\b", r"\bpicturesque\b",
        r"\bbreathtaking\b", r"\brich (cultural )?heritage\b", r"\brenowned\b",
        r"\bworld-class\b", r"\bcommitment to\b", r"\bmust-visit\b", r"\bcutting-edge\b"],
    "vague_attribution": [r"\bexperts (say|argue|note|believe)\b", r"\bobservers\b",
        r"\b(is|are) widely (regarded|considered|seen)\b", r"\bhas been described as\b",
        r"\bsome (critics|argue)\b"],
    "hedging": [r"\b(specific )?details are (limited|scarce)\b", r"\bbased on available information\b",
        r"\bfurther research (may be|is) needed\b", r"\bwhile (specific|detailed) information\b"],
    "structure": [r"\bnot (just|only|merely) [^.]{1,60}\b(but|it's|it is)\b",
        r"\bit'?s not [^.]{1,40}, it'?s\b", r",\s*(highlighting|underscoring|emphasi[sz]ing|reflecting|showcasing|demonstrating|paving the way)\b",
        r"\bfrom [^.,]{2,40} to [^.,]{2,40}\b", r"\bdespite (its|these|this)\b[^.]*\bchallenges\b"],
    "signposting": [r"\bin (summary|conclusion)\b", r"\bit'?s (worth noting|important to note|important to remember)\b",
        r"\blet'?s (explore|dive)\b", r"\bultimately,", r"\boverall,"],
    "chat_residue": [r"\bcertainly!", r"\bgreat question\b", r"\bi hope this helps\b",
        r"\blet me know if\b", r"\bfeel free to\b", r"\bas an ai\b", r"\bknowledge (cutoff|update)\b",
        r"\bhere'?s (a|an|the) "],
    "placeholder": [r"\[(your|insert|company|name|date)[^\]]*\]", r"\b20\d\d-XX-XX\b", r"\blorem ipsum\b"],
    "link_residue": [r"utm_source=(chatgpt|openai|copilot)", r"oaicite", r"contentReference",
        r"cite(turn)?\d*search\d+", r"【\d+†"],
}
FORMAT_CHECKS = {
    "em_dash": r"—",
    "bold": r"\*\*[^*]+\*\*",
    "inline_header_bullet": r"(?m)^\s*[-*]\s+\*\*[^*]+:\*\*",
    "emoji": r"[\U0001F300-\U0001FAFF\u2705\u2728\u274C\u2B50]",
    "title_case_heading": r"(?m)^#{1,6}\s+(?:[A-Z][a-z]+\s+){2,}[A-Z][a-z]+\s*$",
}

def scan(text):
    words = max(len(re.findall(r"\b\w+\b", text)), 1)
    hits = []
    for cat, pats in PATTERNS.items():
        for p in pats:
            for m in re.finditer(p, text, re.I):
                line = text.count("\n", 0, m.start()) + 1
                hits.append({"category": cat, "match": m.group(0), "line": line})
    fmt = {k: len(re.findall(p, text)) for k, p in FORMAT_CHECKS.items()}
    paras = [p for p in re.split(r"\n\s*\n", text) if p.strip()]
    warnings = []
    if fmt["em_dash"] > max(1, len(paras)):
        warnings.append(f"em dashes: {fmt['em_dash']} across {len(paras)} paragraphs (aim <= 1 per paragraph)")
    if fmt["bold"] > max(2, words // 150):
        warnings.append(f"bold spans: {fmt['bold']} (likely over-emphasis)")
    for k in ("inline_header_bullet", "emoji", "title_case_heading"):
        if fmt[k]:
            warnings.append(f"{k.replace('_', ' ')}: {fmt[k]}")
    density = round(len(hits) * 100 / words, 2)
    by_cat = {}
    for h in hits:
        by_cat[h["category"]] = by_cat.get(h["category"], 0) + 1
    return {"words": words, "hits": len(hits), "per_100_words": density,
            "by_category": by_cat, "format_warnings": warnings, "details": hits}

def main():
    args = [a for a in sys.argv[1:] if a != "--json"]
    text = open(args[0], encoding="utf-8").read() if args else sys.stdin.read()
    r = scan(text)
    if "--json" in sys.argv:
        print(json.dumps(r, indent=2, ensure_ascii=False)); return
    print(f"Words: {r['words']}  Hits: {r['hits']}  Per 100 words: {r['per_100_words']}")
    if r["per_100_words"] > 3:
        print("High density: rewrite from the facts up rather than swapping words.")
    for c, n in sorted(r["by_category"].items(), key=lambda x: -x[1]):
        print(f"  {c}: {n}")
    for w in r["format_warnings"]:
        print(f"  ! {w}")
    print()
    for h in r["details"]:
        print(f"  L{h['line']:<4} [{h['category']}] {h['match']}")

if __name__ == "__main__":
    main()
