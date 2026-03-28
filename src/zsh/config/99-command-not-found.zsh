
function command_not_found_handler() {
    local cmd="$1"
    # Only run in interactive sessions
    if [[ -o interactive ]]; then
        # 1. Attempt to blindly reload paths/rehash first
        rehash
        if ! command -v "$cmd" >/dev/null 2>&1; then
             paths.reload
        fi

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
