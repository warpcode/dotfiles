#!/usr/bin/env zsh
# Unit tests for dotfiles.zsh

set -e

# Setup dummy environment
export DOTFILES="$(mktemp -d)"
trap 'rm -rf "$DOTFILES"' EXIT

# Source required setup
source dot_zsh/projects/dotfiles.zsh

# Test 1: dotfiles.setup.submodules in a non-git directory returns 0
(
    cd "$DOTFILES"
    dotfiles.setup.submodules
)
if [[ $? -ne 0 ]]; then
    echo "FAILED: dotfiles.setup.submodules failed in non-git directory" >&2
    exit 1
fi

# Test 2: dotfiles.setup.submodules inside a git repo attempts submodule update
(
    cd "$DOTFILES"
    git init -q
    # Mock git submodule command so it succeeds
    git() {
        if [[ "$1" == "submodule" ]]; then
            return 0
        fi
        command git "$@"
    }
    dotfiles.setup.submodules
)
if [[ $? -ne 0 ]]; then
    echo "FAILED: dotfiles.setup.submodules failed inside git worktree" >&2
    exit 1
fi

echo "ALL DOTFILES TESTS PASSED SUCCESSFULLY!"
