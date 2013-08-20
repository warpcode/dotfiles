# append to the history file, don't overwrite it
shopt -s histappend

# Attempts to save all lines of a multiple-line command in the same history entry
shopt -s cmdhist

# Allow use to re-edit a faild history substitution.
shopt -s histreedit

# History expansions will be verified before execution.
shopt -s histverify

# Entries beginning with space aren't added into history, and duplicates are removed
export HISTCONTROL="ignorespace:erasedups"

# Enable timestamps in history.
export HISTTIMEFORMAT="[%F %T] "

# Allow large history
export HISTSIZE=10000
export HISTFILESIZE=10000

# Execute last command
alias r="fc -s"

# Shortcut to view the history
alias h="history"