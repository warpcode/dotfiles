_installer_package "default" tmux

(( $+commands[rsync] )) || return

# Common rsync I use
alias rsyncc="rsync -vhrlptD --progress"
