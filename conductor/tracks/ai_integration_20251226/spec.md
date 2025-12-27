# Specification: Implement Core AI Tool Integrations

## 1. Overview
This track focuses on integrating OpenCode, Gemini CLI, and Claude Code into the dotfiles environment. The goal is to provide a unified and efficient interface for interacting with these AI tools directly from the command line, leveraging the existing modular Zsh architecture.

## 2. Goals
- Create Zsh aliases and wrapper functions for OpenCode, Gemini CLI, and Claude Code.
- Ensure these tools are easily accessible and configurable via the `src/zsh/apps/` directory.
- Provide a consistent user experience across different AI tools.
- Enable easy updates and management of these tools.

## 3. User Stories
- As a developer, I want to be able to invoke OpenCode with a short alias so that I can quickly generate code.
- As a user, I want to use the Gemini CLI to answer questions without leaving my terminal.
- As an AI enthusiast, I want to integrate Claude Code into my workflow for advanced reasoning tasks.
- As a maintainer, I want to easily update the configurations for these tools in a central location.

## 4. Technical Requirements
- **Zsh Aliases:** Define aliases in `src/zsh/apps/ai.zsh` (or individual files in `src/zsh/apps/`).
- **Configuration:** Ensure that API keys and other sensitive data are handled securely (e.g., via environment variables or a separate secrets file).
- **Dependencies:** Verify that the necessary CLI tools are installed or provide instructions/scripts to install them.
- **Cross-Platform:** Ensure compatibility with both Linux and macOS.

## 5. Non-Functional Requirements
- **Performance:** Aliases should be lightweight and not slow down shell startup.
- **Usability:** Provide clear help messages or usage examples for the new aliases.
- **Maintainability:** Code should follow the project's style guides (modular, prefixed functions).
