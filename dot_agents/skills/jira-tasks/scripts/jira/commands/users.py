import json

def cmd_users(client, args):
    endpoint = "rest/api/3/user/search"
    if args.project:
        endpoint = "rest/api/3/user/assignable/search"

    query_params = {"maxResults": args.max_results}
    if args.query:
        query_params["query"] = args.query
    if args.project:
        query_params["project"] = args.project
    if args.expand:
        query_params["expand"] = args.expand

    response = client.call("GET", endpoint, query_params=query_params)

    if args.raw:
        print(json.dumps(response))
        return

    if args.exact and args.query:
        q = args.query.lower()
        response = [u for u in response if u.get("displayName", "").lower() == q or u.get("emailAddress", "").lower() == q]

    if args.full:
        print(json.dumps(response))
    else:
        result = {u["accountId"]: u["displayName"] for u in response}
        print(json.dumps(result))
