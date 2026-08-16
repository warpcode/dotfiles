---
name: mise
description: Guidance for GitHub Copilot when editing Mise configuration files.
applyTo: "**/mise*.toml"
---

# Mise Configuration Rules

- `brew:` packages must only go in `mise.macos.toml`, never in the main `mise.toml`.
- Platform-specific packages (apt/dnf/pacman) go in the main `mise.toml`.
- `[tools]` section is for mise-managed versioned tools only. System packages belong in `[bootstrap.packages]`.
