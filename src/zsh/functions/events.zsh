# events.zsh - Custom event system for Zsh

typeset -gA _events_hooks

# Register a function for an event.
events.add() {
  local event=$1 func=$2
  (( $+functions[$func] )) || return 1
  [[ " ${_events_hooks[$event]} " == *" $func "* ]] || \
    _events_hooks[$event]+="${_events_hooks[$event]:+ }$func"
}

# Remove a function from an event.
events.remove() {
  local event=$1 func=$2
  _events_hooks[$event]=${${(z)_events_hooks[$event]}:#$func}
}

# Trigger an event
events.trigger() {
  local event=$1; shift
  local func; for func in ${(z)_events_hooks[$event]}; do
    $func "$@"
  done
}

# List all registered events
events.list() {
  local event; for event in ${(k)_events_hooks}; do
    print -P "%F{blue}Event '$event':%f"
    printf "  - %s\n" ${(z)_events_hooks[$event]}
  done
}
