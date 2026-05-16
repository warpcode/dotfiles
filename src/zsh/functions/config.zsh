# config.zsh - Configuration management and templating (delegates to bin/df.config.*)

# Symlink a config file or directory from assets/configs/
config.symlink() {
    "$DOTFILES/bin/df.config.symlink" "$@"
}

# Template a file using gomplate and JSON configs
config.hydrate() {
    "$DOTFILES/bin/df.config.hydrate" "$@"
}

# Replace content between markers
config.block() {
    "$DOTFILES/bin/df.config.block" "$@"
}

# High-level application configuration helper
app.config() {
    # Usage: app.config <src-relative-to-assets> <dst-absolute> [chmod-mode]
    local src="$1" dst="$2" mode="${3:-600}"
    [[ -z "$src" || -z "$dst" ]] && { echo "Usage: app.config <src> <dst> [mode]" >&2; return 1; }

    if [[ "$src" == *.tmpl ]]; then
        config.hydrate "$src" --output "$dst"
    else
        config.symlink "$src" "$dst"
    fi

    # Set permissions if provided
    chmod "$mode" "$dst"
}

# Helper to register an application setup function
app.setup() {
    # Usage: app.setup <app-name-or-event> <setup-func> [event-type]
    local app="$1" func="$2" event="${3:-dotfiles.setup}"
    events.add "$event" "$func"
}
