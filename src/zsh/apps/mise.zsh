(( $+commands[mise] )) || return

eval "$(mise activate zsh)"

# function mise.setup() {
#     mise.setup.config
#     mise install --cd ~ || echo "⚠️ mise install failed. Please run it manually to install tools."
# }
# events.add dotfiles.setup.first mise.setup
#
# function mise.setup.config() {
#     local destination=~/.config/mise/config.toml
#     mkdir -p "$(dirname "$destination")" 2>/dev/null
#     config.hydrate "mise/config.toml.tmpl" --output "$destination"
#     chmod 600 "$destination"
# }

function mise.exec() {
    # Usage: mise.exec <mise-package> <binary> [args...]
    local pkg="$1" bin="$2"; shift 2 || shift $#
    bin.exec mise "$pkg" "$bin" "$@"
}
