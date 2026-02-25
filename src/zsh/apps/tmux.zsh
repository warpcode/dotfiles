function _tmux_basic_git()  {
    # check if $1 is empty
    if [[ -z "$1" ]]; then
        echo "Usage: _tmux_basic_git <session_name>"
        return 1
    fi

    (( $+commands[tmux] )) || (echo "Please install tmux" ; return 1);

    tmux att -t "$1" ||
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

function tmux.setup() {
    tmux.setup.config
}
events.add dotfiles.setup tmux.setup

function tmux.setup.config() {
    config.hydrate "tmux/tmux.conf.tmpl" --output ~/.tmux.conf
}
