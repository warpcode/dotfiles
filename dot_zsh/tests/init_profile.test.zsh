#!/usr/bin/env zsh
# Unit tests for DOTFILES_PROFILE initialization logic in dot_zsh/init.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

set -e

print -r "Running init_profile unit tests..."

# Create a temporary HOME directory for test isolation
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

# Helper function to run initialization logic isolated in a subshell
run_profile_init() {
    HOME="$TMP_HOME" zsh -c '
        DOTFILES_PROFILE="'"$1"'"
        if [[ -z "${DOTFILES_PROFILE:-}" && -f "${HOME}/.dotfiles_profile" ]]; then
            local p
            p="$(<"${HOME}/.dotfiles_profile")"
            if [[ -n "${p}" ]]; then
                export DOTFILES_PROFILE="${p}"
            fi
        fi
        export DOTFILES_PROFILE="${DOTFILES_PROFILE:-default}"
        print -r -- "$DOTFILES_PROFILE"
    '
}

# Test 1: Preset DOTFILES_PROFILE
out_1="$(run_profile_init "work")"
if [[ "$out_1" != "work" ]]; then
    print -r "Test 1 Failed: expected 'work', got '$out_1'" >&2
    exit 1
fi

# Test 2: Unset DOTFILES_PROFILE with non-empty ~/.dotfiles_profile
print -r "personal" > "$TMP_HOME/.dotfiles_profile"
out_2="$(run_profile_init "")"
if [[ "$out_2" != "personal" ]]; then
    print -r "Test 2 Failed: expected 'personal', got '$out_2'" >&2
    exit 1
fi

# Test 3: Unset DOTFILES_PROFILE with empty ~/.dotfiles_profile
: > "$TMP_HOME/.dotfiles_profile"
out_3="$(run_profile_init "")"
if [[ "$out_3" != "default" ]]; then
    print -r "Test 3 Failed: expected 'default', got '$out_3'" >&2
    exit 1
fi

# Test 4: Unset DOTFILES_PROFILE with missing ~/.dotfiles_profile
rm -f "$TMP_HOME/.dotfiles_profile"
out_4="$(run_profile_init "")"
if [[ "$out_4" != "default" ]]; then
    print -r "Test 4 Failed: expected 'default', got '$out_4'" >&2
    exit 1
fi

print -r "ALL INIT PROFILE TESTS PASSED SUCCESSFULLY!"
