# Dotfiles

This is a personal collection of dotfiles for *nix systems, designed to create a consistent and powerful command-line experience across multiple machines. It uses `chezmoi` for managing configurations, templates, and packages, and `mise` for managing runtimes and tools.

## Requirements

The bootstrap script handles most requirements automatically. On a fresh system, you only need:

- **curl** - To download and run the bootstrap script.
- **sudo** access - To configure repositories and run initial system installs.

The following will be bootstrapped automatically:
- **chezmoi** - Dotfiles and state manager.
- **mise** - Polyglot tool manager.

## Features

This dotfiles repository comes with a wide range of features to enhance your shell environment:

-   **Modular Zsh Configuration:** The Zsh configuration is organized into `config`, `functions`, `apps`, and `projects` directories, making it easy to extend and manage.
-   **Cross-Platform Support:** An installation script is provided to install dependencies on macOS, Debian/Ubuntu, Fedora, Arch Linux, and Termux.
-   **Oh My Zsh Integration:** Includes the popular [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) framework for themes and plugins.
-   **AI Command-Line Tools:** A suite of aliases and functions for interacting with AI providers and tooling directly from the command line, including:
    -   `ai.chat <provider>/<model> [prompt]`: Chat against any configured OpenAI-compatible provider (openai, openrouter, groq, docker, ollama, opencode, …).
    -   `ai.models`, `ai.models.free`: List models from a provider, including a free-model filter.
    -   `ai.provider.list`, `ai.provider.define`: Manage the provider registry.
    -   `ai.speckit`, `ai.speckit.init`: Run the [spec-kit](https://github.com/github/spec-kit) CLI via `uvx`.
    -   Providers are defined in [`dot_zsh/apps/ai/providers/`](dot_zsh/apps/ai/providers/) (openai, openrouter, groq, docker, ollama, opencode).
-   **Automatic Python Virtualenv:** Automatically activates and deactivates Python virtual environments (`.venv`) as you navigate your filesystem.
-   **Project-Specific Workflows:** The [`dot_zsh/projects/`](dot_zsh/projects/) directory allows you to define aliases and functions to streamline workflows for your individual projects.
-   **FZF Integration:** Integrates [fzf](https://github.com/junegunn/fzf) for powerful fuzzy history search.
-   **Neovim:** Configurable via [`dot_zsh/projects/neovim.zsh`](dot_zsh/projects/neovim.zsh), which provides `nvim.cd` / `nvim.edit` helpers to clone and edit the [warpcode/vim-config](https://github.com/warpcode/vim-config) repository inside a tmux session.
-   **Automatic PATH management:** Automatically scans `/opt/` and `~/.local/opt/` for subdirectories containing `bin`, `sbin`, `usr/bin`, `usr/sbin`, `usr/local/bin`, and `usr/local/sbin`, and adds them to PATH.
-   **KeePassXC Integration:** The [`df.keepass`](dot_local/bin/executable_df.keepass) helper wraps `keepassxc-cli` for vault access.
-   **GitHub Release Installer:** Automatically downloads and installs applications directly from GitHub releases. Supports OS and architecture detection, version management, and creates executable symlinks in a `bin/` directory. Configurable installation directory via `GITHUB_RELEASES_INSTALL_DIR` environment variable (defaults to `~/.local/opt`).

## Installation

The recommended way to install these dotfiles is via the bootstrap script:

```bash
# Using curl
curl -fsSL https://raw.githubusercontent.com/warpcode/dotfiles/master/install.sh | bash

# Using wget
wget -O- https://raw.githubusercontent.com/warpcode/dotfiles/master/install.sh | bash
```

This script will:
1. Detect your OS and install core dependencies (`git`, `zsh`, `curl`, `jq`).
2. Clone this repository to `${DOTFILES_INSTALL_DIR:-~/.dotfiles}` (overridable).
3. Install `chezmoi` and `mise` if missing.
4. Run `mise bootstrap --only packages` for system packages.
5. Apply the dotfiles via `chezmoi init --apply` (this is what sets `zsh` as the default shell and runs the `run_once_after_*` scripts).

### Manual Installation (Optional)

If you prefer to install manually:

1.  Clone the repository:
    ```bash
    git clone https://github.com/warpcode/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ```

2.  Run the installer:
    ```bash
    ./install.sh
    ```

### Installing Applications from GitHub Releases

Helper functions in [`dot_zsh/functions/github.zsh`](dot_zsh/functions/github.zsh) fetch and install GitHub release artifacts:

- `github.get_latest_release <owner>/<repo>` — returns the latest tag.
- `github.get_asset_url <owner>/<repo> <pattern>` — resolves a matching release asset URL (auto-detects OS/arch suffixes).
- `github.install_release <owner>/<repo> <pattern> [dest_dir]` — downloads the matching asset, extracts `.tar.gz`/`.zip`, flattens top-level `bin/`, `sbin/`, `usr/`, or `lib/` dirs, and symlinks executables into `bin/`.

Extraction lands in `$GITHUB_RELEASES_INSTALL_DIR` (default `~/.local/opt`). Set the variable to override.

## External Dependencies

This repository has no git submodules. All configuration is bundled in-tree; vendored snippets live alongside their consumers (e.g. [`dot_zsh/config/50-oh-my-zsh.zsh`](dot_zsh/config/50-oh-my-zsh.zsh) for Oh My Zsh integration).

To update vendored tool configurations after pulling, re-apply with chezmoi:

```bash
chezmoi apply
```

## Troubleshooting

### Dependencies not installing?
- Ensure your OS is supported (macOS, Debian/Ubuntu, Fedora, Arch Linux, Termux)
- Check that you have `sudo` access for system package installation
- For GitHub releases, ensure `curl`, `jq`, and `tar` are available

### Conflicts with existing configuration?
- The dotfiles use `chezmoi` to manage configuration files. If there is a conflict in your home directory, `chezmoi diff` or `chezmoi apply` will prompt you to merge or overwrite changes.
- Check for conflicts in `~/.zshrc`, `~/.gitconfig`, etc.
- Machine-local overrides can be added to `~/.zshrc.local` (sourced at the end of [`dot_zshrc.tmpl`](dot_zshrc.tmpl)).

### Profiles
- Different configurations and packages are conditionally loaded based on profiles (`default`, `work`, `phone`).
- The active profile is stored in `~/.dotfiles_profile` and read automatically by Chezmoi to apply profile-specific constraints on packages and configurations.

### Customizing the setup
- Add personal aliases/functions to `~/.zshrc.local` (sourced after the main config).
- Add project-specific settings as new files under `dot_zsh/projects/`.
- Modify `GITHUB_RELEASES_INSTALL_DIR` to change where GitHub releases are installed.

## Customization

### Adding new applications
Create a new file in [`dot_zsh/apps/yourapp.zsh`](dot_zsh/apps/):
```zsh
# Add app-specific configuration
alias youralias="yourapp --option"
```

### Project-specific configurations
Add files to [`dot_zsh/projects/yourproject.zsh`](dot_zsh/projects/) for project-specific aliases and functions.

### Overriding settings
Add machine-local aliases or environment overrides to `~/.zshrc.local`. It is sourced at the end of [`dot_zshrc.tmpl`](dot_zshrc.tmpl), after the main configuration.

