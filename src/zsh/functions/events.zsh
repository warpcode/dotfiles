# events.zsh - Custom event system for Zsh
#
# This module provides a system for registering and triggering custom events.
# Functions can be registered for specific events and will be called when the event is triggered.
# Events can pass arguments to all registered functions.
#
# Usage:
#   _events_add_hook "event_name" function_name
#   _events_trigger "event_name" [args...]
#   _events_list_hooks

# Associative array mapping event names to space-separated function lists
typeset -A _events_hooks

# Register a function for a specific event
# @param event The event name
# @param func The function name to register
# @return 0 on success, 1 on error
_events_add_hook() {
    local event=$1
    local func=$2

    # Validate function exists
    if ! (( $+functions[$func] )); then
        echo "Error: Function '$func' does not exist" >&2
        return 1
    fi

    # Add to event's function list (space-separated), avoiding duplicates
    if [[ ${_events_hooks[$event]} =~ (^|[[:space:]])${func}($|[[:space:]]) ]]; then
        # Already registered
        return 0
    fi

    if [[ -n ${_events_hooks[$event]} ]]; then
        _events_hooks[$event]+=" $func"
    else
        _events_hooks[$event]=$func
    fi
}

# Trigger an event, calling all registered functions with passed arguments
# @param event The event name
# @param args Arguments to pass to registered functions
_events_trigger() {
    local event=$1
    shift  # Remove event name, pass remaining args to hooks

    # Check if event has any hooks
    if [[ -z ${_events_hooks[$event]} ]]; then
        return 0
    fi

    # Call each registered function with arguments
    for func in ${(s: :)_events_hooks[$event]}; do
        $func "$@"
    done
}

# List all registered hooks for debugging
# @return 0
_events_list_hooks() {
    for event in ${(k)_events_hooks}; do
        echo "Event '$event':"
        for func in ${(s: :)_events_hooks[$event]}; do
            echo "  - $func"
        done
    done
}