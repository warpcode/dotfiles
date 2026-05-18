import json
from ..client import JIRA_API_VERSION

def cmd_fields(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/field"
    response = client.call("GET", endpoint)

    if args.raw:
        print(json.dumps(response))
        return

    if args.filter:
        f = args.filter.lower()
        response = [item for item in response if f in item.get("name", "").lower()]

    result = {item["id"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_statuses(client, args):
    if args.project:
        endpoint = f"rest/api/{JIRA_API_VERSION}/project/{args.project}/statuses"
        response = client.call("GET", endpoint)
        # Flatten statuses from all issue types
        all_statuses = []
        seen_ids = set()
        for itype in response:
            for status in itype.get("statuses", []):
                sid = status["id"]
                if sid not in seen_ids:
                    all_statuses.append(status)
                    seen_ids.add(sid)
        response = all_statuses
    else:
        endpoint = f"rest/api/{JIRA_API_VERSION}/status"
        response = client.call("GET", endpoint)

    if args.raw:
        print(json.dumps(response))
        return

    result = {
        item["id"]: {
            "name": item["name"],
            "category": item.get("statusCategory", {}).get("name")
        }
        for item in response
    }

    if args.category:
        cat = args.category.lower().replace(" ", "-")
        result = {k: v for k, v in result.items() if v["category"].lower().replace(" ", "-") == cat}

    print(json.dumps(result))

def cmd_types(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/issuetype"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["id"]: {"name": item["name"], "subtask": item.get("subtask")} for item in response}
    print(json.dumps(result))

def cmd_priorities(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/priority"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["id"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_resolutions(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/resolution"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["id"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_projects(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/project"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["key"]: item["name"] for item in response}
    print(json.dumps(result))
