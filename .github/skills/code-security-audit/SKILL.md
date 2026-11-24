---
name: code-security-audit
description: >
  Audit source code and application configurations for security vulnerabilities,
  injection flaws (SQLi, XSS, CSRF, Command Injection), SSRF, deserialization flaws,
  authentication/authorization bypasses, secret leakage, and insecure headers.
  Use when reviewing PRs for security, running pre-deployment security audits,
  verifying listening socket exposure, or scanning for OWASP Top 10 risks.
---

# Code Security Audit Knowledge Centre

Reference hub for static application security testing (SAST), configuration hardening, OWASP Top 10 vulnerability patterns, and runtime socket-exposure verification.

## When to Use

- Conducting pre-merge or pre-deployment security reviews and triaging scanner alerts.
- Auditing authentication, authorization/IDOR, session cookie flags, constant-time token checks, and encryption configs.
- Investigating SQLi, XSS, CSRF, mass assignment, file upload traversal, SSRF, OS command injection, or insecure deserialization.
- Scanning for committed secrets, insecure HTTP headers, or outdated/vulnerable dependencies.
- Verifying live TCP bind exposure claims against running services.

## Domain Knowledge Index

| Topic | Resource | Use When |
|---|---|---|
| Configuration & environment hardening | `@references/configuration-hardening.md` | Checking secrets, HTTP security headers, session/cookie flags, cipher configs, and dependency audits |
| Vulnerability patterns & SAST rules | `@references/vulnerability-patterns.md` | Auditing SQLi, XSS, CSRF, IDOR, mass assignment, file uploads, SSRF, command injection, and deserialization |
| Security review report schema | `@templates/security-review-report.md` | Formatting calibrated findings with CWE/OWASP category, location, snippet, and remediation |

## Runtime Verification Scripts

Static reading shows the *intended* bind address; only a live probe proves what the OS accepts. Capture both loopback (bound) and LAN interface (refused) results with `--json` instead of inline `python3 -c` probes:

| Script | Purpose | Run When |
|---|---|---|
| `@scripts/probe_tcp_bind.py` | Attempts a TCP connect (`--port N [--host H] [--expect-bound\|--expect-refused] [--json]`); exits `1` if expectation fails | Confirming whether an unauthenticated listener is loopback-only or LAN-exposed |
