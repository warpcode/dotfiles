function _tmux_basic_git()  {
    # check if $1 is empty
    if [[ -z "$1" ]]; then
        echo "Usage: _tmux_basic_git <session_name>"
        return 1
    fi

    tmux.cli att -t "$1" ||
        tmux \
        new -s "$1" -n "editor" \; \
        send-keys 'e .' C-m\; \
        \
        neww -n git \; \
        send-keys "lazygit" C-m\; \
        \
        neww -n terminal \; \
        \
        selectw -t editor
}

function tmux.cli() {
   tmux.setup.config
   mise.exec tmux@latest tmux
}

function tmux.setup.config() {
    local destination=~/.tmux.conf
    config.symlink "tmux/tmux.conf" "$destination"
    chmod 600 "$destination"
}
