import time
from jira.formatters import flatten_adf

def create_nested_adf(depth):
    if depth == 0:
        return {"type": "text", "text": "hello"}
    return {
        "type": "paragraph",
        "content": [
            create_nested_adf(depth - 1),
            {"type": "text", "text": " world"},
        ]
    }

# Wider generator to hit all branches
adf_mix = {
    "type": "doc",
    "content": [
        # Standard recursive case
        create_nested_adf(5),
        # Empty/missing content
        {"type": "paragraph"},
        {"type": "paragraph", "content": []},
        {"type": "paragraph", "content": None},
        # Non-container specific paths
        {"type": "hardBreak"},
        {"type": "inlineCard", "attrs": {"url": "https://example.com"}},
        {"type": "mention", "attrs": {"text": "@someone"}},
        # Nested list branch added in PR feedback
        {"type": "paragraph", "content": [[{"type": "text", "text": "nested"}]]},
        # else: fallback container paths
        {"type": "bulletList", "content": [{"type": "listItem", "content": [{"type": "text", "text": "bullet"}]}]},
        {"type": "panel", "content": [{"type": "text", "text": "panel text"}]}
    ] * 10
}

def _flatten_adf_list_old(node, parts):
    if node is None:
        return
    if isinstance(node, list):
        for item in node:
            _flatten_adf_list_old(item, parts)
        return
    if not isinstance(node, dict):
        return

    node_type = node.get("type")
    if node_type == "text":
        parts.append(node.get("text", ""))
    elif node_type == "hardBreak":
        parts.append("\n")
    elif node_type == "inlineCard":
        parts.append(node.get("attrs", {}).get("url", ""))
    elif node_type == "mention":
        parts.append(node.get("attrs", {}).get("text", ""))
    elif node_type in ("paragraph", "heading", "listItem", "tableCell"):
        content = node.get("content", [])
        _flatten_adf_list_old(content, parts)
        parts.append("\n")
    elif "content" in node:
        _flatten_adf_list_old(node["content"], parts)

def flatten_adf_old(node):
    parts = []
    _flatten_adf_list_old(node, parts)
    return "".join(parts)

# verify correctness first
assert flatten_adf(adf_mix) == flatten_adf_old(adf_mix)

ITERATIONS = 5000

print("Running benchmarks...")

# Warmup
for _ in range(100):
    flatten_adf_old(adf_mix)
    flatten_adf(adf_mix)

import statistics

old_times = []
new_times = []

for _ in range(5):
    start = time.perf_counter()
    for _ in range(ITERATIONS):
        flatten_adf_old(adf_mix)
    old_times.append(time.perf_counter() - start)

    start = time.perf_counter()
    for _ in range(ITERATIONS):
        flatten_adf(adf_mix)
    new_times.append(time.perf_counter() - start)

old_time = min(old_times)
new_time = min(new_times)

print(f"Iterations: {ITERATIONS}")
print("Input shape: Mixed ADF payload including nested lists, missing contents, and various elements (multiplied 10x)")
print(f"Old time (frozen baseline): {old_time:.4f}s")
print(f"New time (imported flatten_adf): {new_time:.4f}s")
print(f"Improvement: {((old_time - new_time) / old_time) * 100:.2f}%")
