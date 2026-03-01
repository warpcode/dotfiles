(( $+commands[mise] )) || return

eval "$(mise activate zsh)"

function mise.setup() {
    mise.setup.config
    mise install --cd ~ || echo "⚠️ mise install failed. Please run it manually to install tools."
}
events.add dotfiles.setup.first mise.setup

function mise.setup.config() {
    local destination=~/.config/mise/config.toml
    mkdir -p "$(dirname "$destination")" 2>/dev/null
    config.hydrate "mise/config.toml.tmpl" --output "$destination"
    chmod 600 "$destination"
}

function mise.exec() {
    # Usage: mise.exec <mise-package> <binary> [args...]
    #   <mise-package> - The mise package name (e.g., node@20, python@3.12)
    #   <binary>       - The binary name to run (e.g., node, python)
    #   [args...]      - Arguments to pass to the binary

    local mise_package="$1"
    local binary="$2"
    shift 2 || shift $#  # Handle case where insufficient args provided

    # Check if binary exists in PATH
    if (( $+commands[$binary] )); then
        # Run natively installed binary
        "$binary" "$@"
        return $?
    fi

    # Binary not found, verify mise is available
    if ! (( $+commands[mise] )); then
        echo "❌ Neither '$binary' nor 'mise' found in PATH." >&2
        echo "   Install '$binary' natively or install mise first." >&2
        return 1
    fi

    # Run via mise
    mise exec --quiet "$mise_package" -- "$binary" "$@"
}
