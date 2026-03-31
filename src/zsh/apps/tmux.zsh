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

bin.wrap tmux tmux tmux.setup.config

function tmux.setup.config() {
    app.config "tmux/tmux.conf" ~/.tmux.conf
}
