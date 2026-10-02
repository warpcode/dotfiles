# Project Archetypes Changelog Standards

Different project architectures require specialized changelog structures. This document defines the conventions for each major project category.

---

## 1. Libraries, Frameworks & SDKs

**Audience**: Application developers consuming the API.
**Core Priority**: Preserving binary/source compatibility and explicit migration paths.

### Rules
- **Breaking Changes First**: Always placed at the very top of each release entry under an explicit `### Breaking Changes ⚠️` section.
- **Migration Recipes**: Every breaking change must include a concise before/after code snippet or migration instruction.
- **Strict SemVer**: Any alteration to exported type definitions, signatures, or behavior mandates a MAJOR version bump.
- **Deprecation Cycle**: Features must be deprecated in a MINOR release before being removed in the subsequent MAJOR release.

---

## 2. CLI Tools, Dotfiles & Shell Infrastructure

**Audience**: Terminal users, systems engineers, and dotfiles maintainers.
**Core Priority**: Command syntax, environment configuration, and cross-platform behavior.

### Rules
- **Command & Subcommand Callouts**: Group changes by `Commands & Flags Added`, `Commands & Flags Changed/Removed`.
- **Environment & Configuration Variables**: Call out changes to default config files (`~/.config/...`), environment variables (`EXPORT VAR=...`), and path resolutions.
- **Platform Matrix**: Specify OS/architecture impacts (e.g. macOS Darwin vs Linux, ARM64 vs AMD64).
- **Zsh / Bash Subshell Invariants**: Ensure script behavior or shell option changes (`set -e`, `zsh -n`) are explicitly noted.

---

## 3. Web Applications, SaaS & Backend Services

**Audience**: Product managers, frontend teams, operations, and support engineers.
**Core Priority**: Deployment safety, database migrations, and operational preconditions.

### Rules
- **Release Trains / CalVer**: Use deployment timestamps or CalVer (`YYYY-MM-DD` or `YYYY.WW.release`) when continuous delivery is practiced.
- **User-Facing vs Backend Split**: Separate customer-visible UI/UX feature additions from internal backend API improvements.
- **Database Migrations**: Call out any schema migrations, indexing operations, or required data backfills (`### Database & Schema Migrations`).
- **Operational Prerequisites**: Highlight changes requiring environment variable additions, queue drain steps, or rolling deployment constraints.

---

## 4. Monorepos & Multi-Package Repositories

**Audience**: Internal engineering teams developing across packages in a shared repository.
**Core Priority**: Scope isolation and cross-package dependency synchronization.

### Rules
- **Scoped Subheadings**: Group entries by package namespace (e.g. `### @scope/core`, `### @scope/cli`).
- **Path-Filtered Git History**: When compiling release notes for package `A`, filter git history specifically to commits touching `packages/A/**`.
- **Shared / Tooling Section**: Dedicate a section to repository-wide changes (linter upgrades, Turbo/Nx configurations, root lockfiles).

---

## 5. Security & Compliance-Sensitive Software

**Audience**: Security auditors, enterprise compliance officers, and system administrators.
**Core Priority**: Traceability, vulnerability disclosure, and patch verification.

### Rules
- **Standard Identifiers**: Every security entry must reference the associated CVE (e.g. `CVE-2026-12345`) or GitHub Security Advisory (`GHSA-xxxx-xxxx-xxxx`).
- **Severity & Impact**: State the CVSS score, severity level (`Critical`, `High`, `Moderate`), and the attack vector.
- **Affected Version Ranges**: Explicitly define which versions are vulnerable and the minimal safe version for upgrade.
