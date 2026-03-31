# bin.zsh - Binary execution and CLI wrappers

# Execute a binary with a fallback manager
bin.exec() {
    # Usage: bin.exec <fallback-manager> <manager-package> <binary> [args...]
    #   <fallback-manager> - The manager to use if binary not found (e.g., mise, uv)
    #   <manager-package>  - The package name for the manager (e.g., node@20)
    #   <binary>           - The binary name to run (e.g., node)
    #   [args...]          - Arguments to pass to the binary

    local manager="$1" package="$2" binary="$3"
    shift 3 || shift $#

    if (( $+commands[$binary] )); then
        "$binary" "$@"
        return $?
    fi

    if ! (( $+commands[$manager] )); then
        echo "❌ Neither '$binary' nor '$manager' found in PATH." >&2
        return 1
    fi

    case "$manager" in
        mise) mise exec --quiet "$package" -- "$binary" "$@" ;;
        uv)   uv run --package "$package" "$binary" "$@" ;;
        *)    echo "❌ Unsupported fallback manager: $manager" >&2; return 1 ;;
    esac
}

# Define a consistent .cli wrapper for an application
bin.wrap() {
    # Usage: bin.wrap <app-prefix> [<binary-name>] [<pre-exec-func>]
    local app="$1" cmd="${2:-$1}" pre="$3"
    if [[ -n "$pre" ]]; then
        eval "function $app.cli() { $pre; command $cmd \"\$@\"; }"
    else
        eval "function $app.cli() { command $cmd \"\$@\"; }"
    fi
}
