A collection of dotfiles for \*nix systems

# Description

This is my personal compilation of dotfiles that I use. It is used to set up a common environment between \*nix systems.

This project makes use of other open source projects which are listed and linked to within this readme.

This project also makes use of `git subtree` so also listed will be the commands to update these subtree's

# Features

- Automatically scans `/opt/` and `~/.local/opt/` for subdirectories containing `bin`, `sbin`, `usr/bin`, `usr/sbin`, `usr/local/bin`, and `usr/local/sbin`, and adds them to PATH, with user-local paths (`~/.local/opt/`) taking precedence over system paths (`/opt/`).

# Installation

Clone the repository and install dependencies:

```bash
git clone <repository-url> ~/.dotfiles
cd ~/.dotfiles
make install-deps  # Installs git, stow, zsh, jq, tmux, fzf, rsync, wget if needed
make install-generic  # Installs generic dotfiles
make install-work  # Installs work dotfiles (optional)
```

Supported OSes: macOS (requires Homebrew), Ubuntu, Debian, Fedora, Arch Linux.

Uninstall with `make uninstall-generic` or `make uninstall-work`.

# External Dependencies

This project uses `git subtree` to manage external dependencies and stores them in the `vendor/` directory.

The external dependencies were added using the following template and replacing `master` where/if necessary to select the branch to link to

     `git subtree add -P vendor/project --squash git-url master`

Updating a project manually can be used with a similar command and replacing `master` where necessary

     `git subtree pull -P vendor/project --squash git-url master`

## vendor/ohmyzsh

# The Oh My Zsh framework is provided by [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) using the `master` branch.

---

This project uses `git subtree` to manage external dependencies and stores them in the `vendors/` directory.

The external dependies were added using the following template and replacing `master` where/if necessary to select the branch to link to

     `git subtree add -P vendor/project --squash git-url master`

Updating a project manually can be used with a similar command and replacing `master` where necessary

     `git subtree pull -P vendor/project --squash git-url master`

## vendors/nanorc

The nano syntax highlighting repository is provided by [craigbarnes/nanorc](https://github.com/craigbarnes/nanorc) using the `master` branch.
