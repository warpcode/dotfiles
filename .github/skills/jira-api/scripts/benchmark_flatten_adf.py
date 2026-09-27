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

adf = {
    "type": "doc",
    "content": [create_nested_adf(10) for _ in range(100)]
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
assert flatten_adf(adf) == flatten_adf_old(adf)

print("Running benchmarks...")
start = time.time()
for _ in range(1000):
    res = flatten_adf_old(adf)
end = time.time()
old_time = end - start

start = time.time()
for _ in range(1000):
    res = flatten_adf(adf)
end = time.time()
new_time = end - start

print(f"Iterations: 1000")
print(f"Input shape: depth-10 nested dict in a list of 100 items")
print(f"Old time (frozen baseline): {old_time:.4f}s")
print(f"New time (imported flatten_adf): {new_time:.4f}s")
print(f"Improvement: {((old_time - new_time) / old_time) * 100:.2f}%")
