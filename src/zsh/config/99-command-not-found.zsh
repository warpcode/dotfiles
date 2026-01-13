
function command_not_found_handler() {
    local cmd="$1"
    local paths_config="${DOTFILES}/src/zsh/config/01-paths.zsh"
    # Only run intelligent handler in interactive sessions
    # We allow subshells/pipes as long as the user can interact (e.g. via /dev/tty)
    if [[ -o interactive ]]; then
        # 1. Attempt to blindly reload paths/rehash first
        #    This fixes cases where the command was installed in another shell/subshell
        #    but the current shell hasn't updated its PATH or hash table yet.
        rehash
        if ! command -v "$cmd" >/dev/null 2>&1; then
             [[ -f "$paths_config" ]] && source "$paths_config"
             rehash
        fi

        # If found after reload, run it immediately!
        if command -v "$cmd" >/dev/null 2>&1; then
            "$@"
            return $?
        fi

        # 2. Check if we have a recipe for this command
        local recipe_id=$(zinstall.recipe "$cmd")

        if [[ -n "$recipe_id" ]]; then
            echo "💡 Command '$cmd' not found, but can be installed via package '$recipe_id'." >&2
            echo -n "   Install $recipe_id? [Y/n] " >&2

            # Force read from /dev/tty to handle subshells/pipelines where stdin is redirected
            if read -q response < /dev/tty; then
                echo "" >&2
                zinstall.install "$recipe_id" >&2

                # Reload paths regardless of success
                echo "🔄 Reloading paths..." >&2
                [[ -f "$paths_config" ]] && source "$paths_config"
                rehash

                if command -v "$cmd" >/dev/null 2>&1; then
                    # Execute the original command, preserving arguments
                    "$@"
                    return $?
                else
                    echo "❌ Command '$cmd' still not found after installation. You may need to restart your shell." >&2
                    return 127
                fi
            else
                echo "" >&2
            fi
        fi
    fi

    # Check docker images (placeholder from original file)


    # If nothing is found, show original error
    echo "zsh: command not found: $cmd" >&2
    return 127
}
