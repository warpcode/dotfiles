import json
from ..client import JIRA_API_VERSION, get_status_map
from ..formatters import process_issue

def cmd_issues(client, args):
    fields_list = None
    if args.fields:
        fields_list = [f.strip() for f in args.fields.split(",") if f.strip()]

    requested_expands = [e.strip() for e in args.expand.split(",") if e.strip()]

    payload = {"issueIdsOrKeys": args.ids}
    if fields_list:
        payload["fields"] = fields_list
    if requested_expands:
        payload["expand"] = requested_expands

    endpoint = f"rest/api/{JIRA_API_VERSION}/issue/bulkfetch"
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
