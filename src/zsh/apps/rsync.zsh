_installer_package "default" rsync

(( $+commands[rsync] )) || return

# Common rsync I use
alias rsyncc="rsync -vhrlptD --progress"
