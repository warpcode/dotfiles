#!/usr/bin/env zsh

# os.zsh - OS and architecture detection utilities
# Thin wrappers around bin/df.os with in-process env-var caching.

# Detect if running in Termux
os.is_termux() {
    (( $+TERMUX_VERSION )) && [[ -d "$PREFIX" ]]
}

# Detect OS family (macos, debian, fedora, arch, termux, linux, or unknown)
os.family() {
    [[ -n "$__OS_FAMILY" ]] && { echo "$__OS_FAMILY"; return }
    export __OS_FAMILY="$(df.os family)"
    echo "$__OS_FAMILY"
}

# Detect architecture (amd64, arm64, or raw uname)
os.arch() {
    [[ -n "$__OS_ARCH" ]] && { echo "$__OS_ARCH"; return }
    export __OS_ARCH="$(df.os arch)"
    echo "$__OS_ARCH"
}

# Environment checks
os.has_gui() {
    df.os has-gui
}

os.is_headless() {
    df.os is-headless
}

# Filter input lines by architecture patterns
# Usage: os.filter_by_arch "input string" OR echo "input" | os.filter_by_arch
os.filter_by_arch() {
    if [[ -n "${1:-}" ]]; then
        df.os filter "$1"
    else
        df.os filter
    fi
}
