---
name: code-infra-docker
description: >
  Audit, design, and optimize Docker containers, Dockerfiles, and Docker
  Compose service architectures. Use when creating Dockerfiles, troubleshooting
  container builds, optimizing layer caching, auditing multi-container
  networking and volume persistence, or setting up dev environments.
---

# Docker & Container Infrastructure Knowledge Centre

Reference hub for Dockerfile hardening, multi-stage builds, layer caching, Docker Compose network topology, and persistent volume design.

## When to Use

- Authoring or reviewing `Dockerfile` definitions (multi-stage builds, layer ordering, pinned tags, non-root `USER`, `.dockerignore`).
- Auditing `docker-compose.yml` service dependencies (`service_healthy`), isolated networks, and `.env` variable hydration.
- Troubleshooting bloated images, broken layer caches, or mounted volume permission/persistence issues.

## Key Focus Areas

- **Dockerfiles**: Separate build toolchains from lean runtime stages, copy dependency manifests before source code, pin explicit base tags, and enforce non-root execution.
- **Compose & Networks**: Isolate frontend/backend/database networks, gate startup on healthchecks, and avoid hardcoded credentials.
- **Volumes & State**: Use named volumes for stateful datastores and reserve bind mounts for local development hot-reloading.

## Domain Knowledge Index

| Topic | Resource | Use When |
|---|---|---|
| Dockerfile hardening & caching | `@references/dockerfile-best-practices.md` | Auditing multi-stage builds, layer order, non-root users, and `.dockerignore` |
| Compose & network topology | `@references/compose-and-topology.md` | Reviewing service healthchecks, isolated networks, secrets hydration, and volumes |

## Report Template

| Template | Path | Use When |
|---|---|---|
| Container topology report | `@templates/container-topology-report.md` | Documenting base images, service dependency graph, size wins, and hardening findings |
