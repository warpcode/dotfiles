#!/usr/bin/env zsh
# Unit tests for dot_zsh/init.zsh profile initialization logic

set -e

# Setup dummy environment
TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

# Test 1: DOTFILES_PROFILE is already set -> preserves value
(
    export HOME="$TEST_TMP/home1"
    mkdir -p "$HOME"
    echo "from_file" > "$HOME/.dotfiles_profile"
    export DOTFILES_PROFILE="preset_profile"
    export DOTFILES="$TEST_TMP"

    # Source init.zsh with dummy roots/dirs
    source dot_zsh/init.zsh

    if [[ "$DOTFILES_PROFILE" != "preset_profile" ]]; then
        echo "FAILED: Expected preset_profile, got $DOTFILES_PROFILE" >&2
        exit 1
    fi
)

# Test 2: DOTFILES_PROFILE is unset, ~/.dotfiles_profile exists and non-empty -> reads from file
(
    export HOME="$TEST_TMP/home2"
    mkdir -p "$HOME"
    echo "custom_profile" > "$HOME/.dotfiles_profile"
    unset DOTFILES_PROFILE
    export DOTFILES="$TEST_TMP"

    source dot_zsh/init.zsh

    if [[ "$DOTFILES_PROFILE" != "custom_profile" ]]; then
        echo "FAILED: Expected custom_profile, got $DOTFILES_PROFILE" >&2
        exit 1
    fi
)

# Test 3: DOTFILES_PROFILE is unset, ~/.dotfiles_profile exists but empty -> defaults to "default"
(
    export HOME="$TEST_TMP/home3"
    mkdir -p "$HOME"
    touch "$HOME/.dotfiles_profile"
    unset DOTFILES_PROFILE
    export DOTFILES="$TEST_TMP"

    source dot_zsh/init.zsh

    if [[ "$DOTFILES_PROFILE" != "default" ]]; then
        echo "FAILED: Expected default, got $DOTFILES_PROFILE" >&2
        exit 1
    fi
)

# Test 4: DOTFILES_PROFILE is unset, ~/.dotfiles_profile does not exist -> defaults to "default"
(
    export HOME="$TEST_TMP/home4"
    mkdir -p "$HOME"
    unset DOTFILES_PROFILE
    export DOTFILES="$TEST_TMP"

    source dot_zsh/init.zsh

    if [[ "$DOTFILES_PROFILE" != "default" ]]; then
        echo "FAILED: Expected default, got $DOTFILES_PROFILE" >&2
        exit 1
    fi
)

echo "ALL INIT TESTS PASSED SUCCESSFULLY!"
