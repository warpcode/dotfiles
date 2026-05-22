from .metrics import calculate_metrics

def flatten_adf(node):
    """Recursive function to handle nested ADF (Atlassian Document Format) content."""
    if node is None:
        return ""
    if isinstance(node, list):
        return "".join(flatten_adf(item) for item in node)
    if not isinstance(node, dict):
        return ""

    node_type = node.get("type")
    if node_type == "text":
        return node.get("text", "")
    if node_type == "hardBreak":
        return "\n"
    if node_type == "inlineCard":
        return node.get("attrs", {}).get("url", "")
    if node_type == "mention":
        return node.get("attrs", {}).get("text", "")
    if node_type in ("paragraph", "heading", "listItem", "tableCell"):
        content = node.get("content", [])
        return flatten_adf(content) + "\n"
    if "content" in node:
        return flatten_adf(node["content"])
    return ""

def process_issue(issue, requested_expands, full_issue=False, status_map=None):
    """Replicates the ISSUE_PROCESSOR_JQ logic for a single issue and adds statistical metrics."""
    fields = issue.get("fields", {})

    # Extract comments
    comment_data = fields.get("comment", {})
    comments = []
    for c in comment_data.get("comments", []):
        comments.append({
            "author": c.get("author", {}).get("displayName"),
            "created": c.get("created"),
            "updated": c.get("updated"),
            "body": flatten_adf(c.get("body")).rstrip("\n")
        })

    # Extract assignee and parent safely
    assignee_data = fields.get("assignee")
    assignee_name = assignee_data.get("displayName") if assignee_data else "Unassigned"

    parent_data = fields.get("parent")
    parent_key = parent_data.get("key") if parent_data else None

    result = {
        "id": issue.get("id"),
        "key": issue.get("key"),
        "parent": parent_key,
        "type": fields.get("issuetype", {}).get("name"),
        "summary": fields.get("summary"),
        "description": flatten_adf(fields.get("description")).rstrip("\n"),
        "comment": {
            "total": comment_data.get("total", 0),
            "comments": comments
        },
        "assignee": assignee_name,
        "status": fields.get("status", {}).get("name"),
        "priority": fields.get("priority", {}).get("name"),
        "labels": fields.get("labels", []),
        "components": [comp.get("name") for comp in fields.get("components", [])],
        "created": fields.get("created"),
        "updated": fields.get("updated")
    }

    # Statistical Metrics (Advanced Reporting)
    metrics = calculate_metrics(issue, status_map)
    if metrics:
        result["metrics"] = metrics

    # Handle requested expands
    for expand_key in requested_expands:
        if expand_key in issue:
            val = issue[expand_key]
            if expand_key == "changelog":
                processed_histories = []
                for h in val.get("histories", []):
                    items = []
                    for item in h.get("items", []):
                        items.append({
                            "field": item.get("field"),
                            "fieldId": item.get("fieldId"),
                            "from": item.get("from"),
                            "fromString": item.get("fromString"),
                            "to": item.get("to"),
                            "toString": item.get("toString")
                        })
                    processed_histories.append({
                        "id": h.get("id"),
                        "author": h.get("author", {}).get("displayName"),
                        "author_id": h.get("author", {}).get("accountId"),
                        "created": h.get("created"),
                        "items": items
                    })
                result["changelog"] = {"histories": processed_histories}
            elif expand_key == "transitions":
                transitions = []
                for t in val:
                    transitions.append({
                        "transitionId": t.get("id"),
                        "transitionname": t.get("name"),
                        "statusId": t.get("to", {}).get("id"),
                        "statusName": t.get("to", {}).get("name"),
                        "hasScreen": t.get("hasScreen"),
                        "isGlobal": t.get("isGlobal"),
                        "isInitial": t.get("isInitial"),
                        "isAvailable": t.get("isAvailable"),
                        "isConditional": t.get("isConditional"),
                        "isLooped": t.get("isLooped")
                    })
                result["transitions"] = transitions
            else:
                result[expand_key] = val

    if full_issue:
        result["original"] = issue

    return result
