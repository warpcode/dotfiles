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

        seen_ids = set()
        seen_add = seen_ids.add

        if args.raw:
            flattened = []
            flat_append = flattened.append
            for itype in response:
                statuses = itype.get("statuses")
                if not statuses:
                    continue
                for status in statuses:
                    sid = status["id"]
                    if sid not in seen_ids:
                        seen_add(sid)
                        flat_append(status)
            print(json.dumps(flattened))
            return

        cat_filter = args.category.lower().replace(" ", "-") if args.category else None
        result = {}

        for itype in response:
            statuses = itype.get("statuses")
            if not statuses:
                continue
            for status in statuses:
                sid = status["id"]
                if sid not in seen_ids:
                    seen_add(sid)
                    cat_name = (status.get("statusCategory") or {}).get("name")
                    if cat_filter:
                        if not cat_name or cat_name.lower().replace(" ", "-") != cat_filter:
                            continue
                    result[sid] = {"name": status["name"], "category": cat_name}

        print(json.dumps(result))
        return

    endpoint = f"rest/api/{JIRA_API_VERSION}/status"
    response = client.call("GET", endpoint)

    if args.raw:
        print(json.dumps(response))
        return

    cat_filter = args.category.lower().replace(" ", "-") if args.category else None
    result = {}
    for item in response:
        sid = item["id"]
        cat_name = (item.get("statusCategory") or {}).get("name")
        if cat_filter:
            if not cat_name or cat_name.lower().replace(" ", "-") != cat_filter:
                continue
        result[sid] = {"name": item["name"], "category": cat_name}

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
