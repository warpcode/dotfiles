#!/usr/bin/env python3
"""Verify whether a TCP listener is reachable on a given interface.

Security use case: a local service (AI bridge, callback listener, dev server) is
meant to be loopback-only. Reading the source shows the intended bind address,
but only a live probe proves what the OS actually accepts. `ss`/`lsof` are not
portable and are often absent in minimal containers; a direct connect attempt is
unambiguous and needs no external tooling.

Replaces the `python3 -c` one-liner that this was written for, which the repo's
AGENTS.md forbids ("No Inline Python Scripts") and which could not express a
portable, self-documenting check.

Usage:
    probe_tcp_bind.py --port 18081 [--host 127.0.0.1] [--timeout 3] [--json]
    probe_tcp_bind.py --port 18081 --expect-refused --host 192.168.1.13

Options:
    --port PORT          TCP port to probe                       [required]
    --host HOST          Interface to probe from
                         [default: 127.0.0.1]
    --timeout SECONDS    Per-attempt connect timeout              [default: 3]
    --expect-bound       Fail unless the port ACCEPTS a connection
    --expect-refused     Fail unless the port REFUSES a connection
    --json               Machine-readable output
    -h, --help           Show this help

Exit codes:
    0  probe result matched the expectation (or no expectation was given)
    1  expectation not met (e.g. --expect-refused but the port was reachable)
    2  usage error

Read-only: opens a TCP connection and closes it. Sends no payload.
"""

import argparse
import json
import socket
import sys


def probe(host, port, timeout):
    """Attempt one TCP connect. Returns (reachable: bool, detail: str)."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, "connection accepted"
    except ConnectionRefusedError:
        return False, "connection refused"
    except socket.timeout:
        # Timed out: filtered/blackholed rather than closed. Treat as NOT
        # reachable but label it distinctly -- a DROP means "listening but silent",
        # which is a different exposure from a clean refusal.
        return False, "connection timed out (filtered)"
    except OSError as exc:
        return False, f"unreachable: {exc.strerror or exc}"


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="probe_tcp_bind.py",
        description="Verify whether a TCP listener is reachable on an interface.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--port", type=int, required=True, help="TCP port to probe")
    parser.add_argument("--host", default="127.0.0.1", help="interface to probe (default: 127.0.0.1)")
    parser.add_argument("--timeout", type=float, default=3.0, help="connect timeout in seconds (default: 3)")
    parser.add_argument("--expect-bound", action="store_true", help="fail unless the port accepts connections")
    parser.add_argument("--expect-refused", action="store_true", help="fail unless the port refuses connections")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    args = parser.parse_args(argv)

    if args.expect_bound and args.expect_refused:
        print("error: --expect-bound and --expect-refused are mutually exclusive",
              file=sys.stderr)
        return 2
    if not 1 <= args.port <= 65535:
        print(f"error: invalid port {args.port}", file=sys.stderr)
        return 2

    reachable, detail = probe(args.host, args.port, args.timeout)

    # Decide whether the observed state is what the caller expected.
    if args.expect_bound:
        met = reachable
        expectation = "bound"
    elif args.expect_refused:
        met = not reachable
        expectation = "refused"
    else:
        met = True
        expectation = "none"

    result = {
        "host": args.host,
        "port": args.port,
        "reachable": reachable,
        "detail": detail,
        "expectation": expectation,
        "expectation_met": met,
    }

    if args.json:
        print(json.dumps(result))
    else:
        verdict = "REACHABLE" if reachable else "NOT-REACHABLE"
        print(f"== {args.host}:{args.port}  {verdict}  ({detail})")
        if expectation != "none":
            state = "PASS" if met else "FAIL"
            print(f"   expected {expectation}: {state}")

    return 0 if met else 1


if __name__ == "__main__":
    sys.exit(main())