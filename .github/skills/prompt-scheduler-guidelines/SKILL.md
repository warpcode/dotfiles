---
name: prompt-scheduler-guidelines
description: Design, register, and maintain user-space scheduled tasks across macOS and Linux dotfiles environments. Includes safety guidelines, logging standards, and systemd/launchd service templates.
---

# User-Space Scheduler Guidelines

Codify scheduled workflows to automate maintenance tasks across macOS and Linux without root privileges.

## 🚀 Declarative Task Definition
- Tasks are defined declaratively as JSON files specifying `name`, `schedule` (hourly, daily, weekly), and `command`.
- Do not make assumptions about the strict directory location where the final JSON task definitions are stored.

## ⚙️ Service Registration
- **macOS (launchd)**: Register user plists inside `~/Library/LaunchAgents/` using modern `launchctl bootstrap/bootout`.
- **Linux (systemd)**: Register user service and timer files inside `~/.config/systemd/user/` and manage with `systemctl --user`.

## 📈 Logging & Maintenance
- **macOS (launchd)**: Redirection (`>`) in the launchd program arguments to truncate logs on every run and prevent infinite disk growth.
- **Linux (systemd)**: Standardize logging via `StandardOutput=journal` and query via `journalctl --user`.

## 📂 Templates
Templates for macOS launchd and Linux systemd configurations are stored inside the skill's `templates/` directory as reusable example files.
