# Make vim the default editor
export EDITOR="vim"

# Entries beginning with space aren't added into history, and duplicates are removed
export HISTCONTROL="ignorespace:erasedups"

# Enable timestamps in history.
export HISTTIMEFORMAT="[%F %T] "

# Allow large history
export HISTSIZE=10000
export HISTFILESIZE=10000

# Make some commands not show up in history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"
