function command_not_found_handler() {
    local cmd="$1"

    # In interactive sessions, attempt to reload paths/rehash first
    if [[ -o interactive ]]; then
        rehash
        command -v "$cmd" >/dev/null 2>&1 || path.reload

        # If found after reload, run it immediately!
        if command -v "$cmd" >/dev/null 2>&1; then
            "$@"
            return $?
        fi
    fi

    # Command not found
    echo "zsh: command not found: $cmd" >&2
    return 127
}
