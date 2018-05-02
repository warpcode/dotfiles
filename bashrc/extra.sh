# Files will be created with these permissions:
# files 644 -rw-r--r--
# dirs  755 drwxr-xr-x
umask 022

# append to the history file, don't overwrite it
shopt -s histappend

# Attempts to save all lines of a multiple-line command in the same history entry
shopt -s cmdhist

# Allow us to re-edit a failed history substitution.
shopt -s histreedit

# History expansions will be verified before execution.
shopt -s histverify

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
