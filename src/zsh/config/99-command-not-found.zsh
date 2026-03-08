
function command_not_found_handler() {
    local cmd="$1"
    # Only run intelligent handler in interactive sessions
    # We allow subshells/pipes as long as the user can interact (e.g. via /dev/tty)
    if [[ -o interactive ]]; then
        # 1. Attempt to blindly reload paths/rehash first
        #    This fixes cases where the command was installed in another shell/subshell
        #    but the current shell hasn't updated its PATH or hash table yet.
        rehash
        if ! command -v "$cmd" >/dev/null 2>&1; then
             paths.reload
        fi

        # If found after reload, run it immediately!
        if command -v "$cmd" >/dev/null 2>&1; then
            "$@"
            return $?
        fi

        # 2. Check if we have a recipe for this command
        # local recipe_id=$(pkg.find "$cmd")

        # if [[ -n "$recipe_id" ]]; then
        #     # Potential recursion point: disabled for stability
        #     # pkg.exec "$@"
        #     # return $?
        # fi
    fi

    # Check docker images (placeholder from original file)


    # If nothing is found, show original error
    echo "zsh: command not found: $cmd" >&2
    return 127
}
