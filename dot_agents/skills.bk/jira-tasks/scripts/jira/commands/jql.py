import json
from ..client import JIRA_API_VERSION, get_status_map
from ..formatters import process_issue
from ..utils import die

def cmd_jql(client, args):
    mandatory_fields = ["parent", "summary", "description", "status", "assignee", "issuetype", "comment", "created", "updated", "priority", "labels", "components"]
    fields_list = mandatory_fields
    if args.fields:
        fields_list = list(set(mandatory_fields + [f.strip() for f in args.fields.split(",") if f.strip()]))

    payload = {
        "jql": args.query,
        "maxResults": args.max_results,
        "fields": fields_list
    }

    requested_expands = [e.strip() for e in args.expand.split(",") if e.strip()]
    if requested_expands:
        payload["expand"] = ",".join(requested_expands)

    if args.param:
        for p in args.param:
            if '=' not in p:
                die(f"Error: --param requires key=value format (got: {p})")
            k, v = p.split('=', 1)
            # Try to convert to number if possible to match JQ behavior
            if v.isdigit():
                v = int(v)
            payload[k] = v

    endpoint = f"rest/api/{JIRA_API_VERSION}/search/jql"
    response = client.call("POST", endpoint, payload)

    if args.raw:
        print(json.dumps(response))
        return

    status_map = None
    if "changelog" in requested_expands:
        status_map = get_status_map(client, args.project)

    processed_issues = [process_issue(issue, requested_expands, args.full_issue, status_map) for issue in response.get("issues", [])]
    output = {
        "isLast": response.get("isLast", True),
        "resultsOnPage": len(processed_issues),
        "nextPageToken": response.get("nextPageToken"),
        "issues": processed_issues
    }
    # Include any top-level expands present in source
    for expand_key in requested_expands:
        if expand_key in response:
            output[expand_key] = response[expand_key]

    print(json.dumps(output))
