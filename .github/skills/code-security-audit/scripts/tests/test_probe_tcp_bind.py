import json
import os
import socket
import subprocess
import threading
import unittest

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PROBE = os.path.join(SCRIPTS_DIR, "probe_tcp_bind.py")


def _free_port():
    """Reserve and release a port so nothing is listening on it."""
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class TestProbeTcpBind(unittest.TestCase):

    def test_help_documents_flags(self):
        res = subprocess.run([PROBE, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        for flag in ("--port", "--host", "--expect-bound", "--expect-refused", "--json"):
            self.assertIn(flag, res.stdout)

    def test_refused_when_nothing_listening(self):
        port = _free_port()
        res = subprocess.run([PROBE, "--port", str(port), "--json"],
                             capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        data = json.loads(res.stdout)
        self.assertFalse(data["reachable"])

    def test_bound_when_listener_present(self):
        port = _free_port()
        server = socket.socket()
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("127.0.0.1", port))
        server.listen(1)
        try:
            res = subprocess.run([PROBE, "--port", str(port), "--expect-bound"],
                                 capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            self.assertIn("REACHABLE", res.stdout)
        finally:
            server.close()

    def test_expect_refused_fails_when_reachable(self):
        port = _free_port()
        server = socket.socket()
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("127.0.0.1", port))
        server.listen(1)
        try:
            res = subprocess.run([PROBE, "--port", str(port), "--expect-refused"],
                                 capture_output=True, text=True)
            self.assertEqual(res.returncode, 1, "reachable port must fail --expect-refused")
            self.assertIn("FAIL", res.stdout)
        finally:
            server.close()

    def test_mutually_exclusive_expectations(self):
        res = subprocess.run([PROBE, "--port", "1", "--expect-bound", "--expect-refused"],
                             capture_output=True, text=True)
        self.assertEqual(res.returncode, 2)

    def test_invalid_port_is_usage_error(self):
        res = subprocess.run([PROBE, "--port", "99999"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 2)

    def test_missing_required_port_is_usage_error(self):
        res = subprocess.run([PROBE], capture_output=True, text=True)
        self.assertNotEqual(res.returncode, 0)


if __name__ == "__main__":
    unittest.main()