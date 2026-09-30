import json
from ..utils import die

def cmd_call(client, args):
    if args.method != "GET":
        die("Error: direct API calls are read-only; only GET is allowed.")
    response = client.call(args.method, args.endpoint, payload=json.loads(args.payload) if args.payload else None)
    print(json.dumps(response))
