# Initial Concept\nPersonal collection of dotfiles for *nix systems, designed to create a consistent and powerful command-line experience across multiple machines, with a strong focus on developers, DevOps engineers, and AI-driven workflows.

# Product Guide

## Target Audience
- **Software Developers:** Seeking a highly productive and customized terminal environment.
- **DevOps Engineers:** Aiming to automate environment setup and management across various systems.
- **AI-Focused Users:** Leveraging agentic tools and AI-integrated workflows directly from the CLI.

## Primary Goals
- **Turn-Key Environment:** Create a setup that works instantly on any new machine with minimal manual intervention.
- **AI Integration:** Provide a robust set of aliases, functions, and wrappers for interacting with AI services (e.g., OpenCode, Gemini, Crush).
- **Automated Tool Management:** Streamline the installation and updating of CLI tools, particularly those sourced from GitHub releases.

## Key Features
- **Modular Zsh Configuration:** A structured organization of configuration, functions, applications, and project-specific settings.
- **Automated Multi-Platform Installer:** A system that handles dependencies via package managers (apt, dnf, etc.) and direct GitHub release downloads.
- **Agentic Tooling Suite:** Deeply integrated AI command-line tools for code generation, chat, and system management.

## Project Guidelines
- **Idempotency:** The configuration and installation processes must be safe to run multiple times without causing side effects or errors.
- **Cross-Platform Compatibility:** The system must support major *nix environments, specifically Linux and macOS.
