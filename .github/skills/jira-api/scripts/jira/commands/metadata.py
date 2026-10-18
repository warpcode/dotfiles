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

def _iter_project_statuses(response):
    seen = set()
    for itype in response:
        for status in (itype.get("statuses") or []):
            sid = status["id"]
            if sid not in seen:
                seen.add(sid)
                yield status

def _format_statuses(statuses, category_filter=None):
    cat_filter = category_filter.lower().replace(" ", "-") if category_filter else None
    result = {}
    for item in statuses:
        cat_name = (item.get("statusCategory") or {}).get("name")
        if cat_filter:
            if not cat_name or cat_name.lower().replace(" ", "-") != cat_filter:
                continue
        result[item["id"]] = {"name": item["name"], "category": cat_name}
    return result

def cmd_statuses(client, args):
    if args.project:
        endpoint = f"rest/api/{JIRA_API_VERSION}/project/{args.project}/statuses"
        response = client.call("GET", endpoint)
        statuses = list(_iter_project_statuses(response))
    else:
        endpoint = f"rest/api/{JIRA_API_VERSION}/status"
        response = client.call("GET", endpoint)
        statuses = response

    if args.raw:
        print(json.dumps(statuses))
        return

    result = _format_statuses(statuses, args.category)
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
