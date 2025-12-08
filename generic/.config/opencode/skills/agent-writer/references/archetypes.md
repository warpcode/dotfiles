# Agent Archetypes Quick Reference

## Agent Archetypes

| Archetype | Mode | Temp | Tools | Permission | Focus | Use When |
|-----------|------|------|-------|------------|-------|----------|
| Security Auditor | subagent | 0.1 | read, search, context7 | {} | Vulnerabilities | Unbiased analysis |
| Code Reviewer | subagent | 0.2 | read, search, context7 | {} | Quality | Feedback needed |
| Doc Writer | subagent | 0.6 | write, edit, read, context7 | ask | Docs | Create/update docs |
| Test Generator | subagent | 0.3 | write, bash, read, context7 | ask | Tests | Coverage needed |
| Refactorer | subagent | 0.3 | edit, bash, read, context7 | ask | Cleanup | Improve code |
| Feature Builder | primary | 0.4 | all | ask | Features | New functionality |
| Bug Fixer | primary | 0.3 | edit, bash, read, context7 | ask | Fixes | Diagnose/fix bugs |
| Perf Optimizer | subagent | 0.2 | edit, bash, read, context7 | ask | Performance | Slow code |

## Ten Commandments

1. Specific: Eliminate ambiguity
2. Complete: Cover all cases
3. Safe: Defense in depth
4. Clear: Scannable structure
5. Actionable: Measurable outcomes
6. Realistic: Match tools
7. Bounded: Explicit scope
8. Transparent: Explain reasoning
9. Adaptive: Decision frameworks
10. Humble: Acknowledge limits

## Final Checklist

**Configuration**: Detailed description, essential tools, restrictive permissions, matching temperature, correct mode, model only if requested.

**Instructions**: Clear role/scope/methodology/edge cases/quality/safety/communication.

**Security**: Deny dangerous ops, prevent credential exposure, mandate secure patterns, enforce boundaries.

**Integration**: Scan target platform config for components. Reference by exact names. Instruct agents to integrate.

**Documentation Priority**: Use context7 tool first for documentation needs.