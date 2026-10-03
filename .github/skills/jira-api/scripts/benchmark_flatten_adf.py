import time
from jira.formatters import flatten_adf

def create_nested_adf(depth):
    if depth == 0:
        return {"type": "text", "text": "hello"}
    if depth % 3 == 0:
        return {
            "type": "paragraph",
            "content": [
                {"type": "inlineCard", "attrs": {"url": "https://example.com"}},
                create_nested_adf(depth - 1),
            ]
        }
    elif depth % 3 == 1:
        return {
            "type": "paragraph",
            "content": [
                {"type": "mention", "attrs": {"text": "@user"}},
                create_nested_adf(depth - 1),
            ]
        }
    return {
        "type": "paragraph",
        "content": [
            create_nested_adf(depth - 1),
            {"type": "text", "text": " world"},
        ]
    }

adf = {
    "type": "doc",
    "content": [create_nested_adf(10) for _ in range(100)]
}

def flatten_adf_old(node):
    """Old recursive implementation without accumulator list or dict type checks."""
    if node is None:
        return ""
    if isinstance(node, list):
        return "".join(flatten_adf_old(item) for item in node)
    if not isinstance(node, dict):
        return ""

    parts = []
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
        parts.append(flatten_adf_old(content))
        parts.append("\n")
    elif "content" in node:
        parts.append(flatten_adf_old(node["content"]))

    return "".join(parts)

# verify correctness first
assert flatten_adf(adf) == flatten_adf_old(adf)

# Benchmark using minimum of multiple runs for accuracy
old_times = []
for _ in range(5):
    start = time.perf_counter()
    for _ in range(100):
        res = flatten_adf_old(adf)
    old_times.append(time.perf_counter() - start)

new_times = []
for _ in range(5):
    start = time.perf_counter()
    for _ in range(100):
        res = flatten_adf(adf)
    new_times.append(time.perf_counter() - start)

old_time = min(old_times)
new_time = min(new_times)

print(f"Old time: {old_time:.4f}s")
print(f"New time: {new_time:.4f}s")
print(f"Improvement: {((old_time - new_time) / old_time) * 100:.2f}%")
