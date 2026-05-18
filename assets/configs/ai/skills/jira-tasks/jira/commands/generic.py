import json

def cmd_call(client, args):
    response = client.call(args.method, args.endpoint, payload=json.loads(args.payload) if args.payload else None)
    print(json.dumps(response))
