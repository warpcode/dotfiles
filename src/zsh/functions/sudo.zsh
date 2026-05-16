# sudo.zsh - Sudo wrapper
_run_sudo() {
    if (( EUID == 0 )); then
        "$@"
    elif (( $+commands[sudo] )); then
        command sudo "$@"
    elif (( $+commands[su] )); then
        command su -c "${(q)*}"
    else
        echo "Error: Neither sudo nor su is available, and not running as root." >&2
        return 1
    fi
}
