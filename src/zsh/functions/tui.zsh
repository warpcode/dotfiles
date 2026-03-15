#!/usr/bin/env zsh

# tui.zsh - Terminal UI Components for Dotfiles
#
# Provides reusable UI components for interactive shell scripts.

# @description Read user input with support for defaults, validation, and optionality.
# @param $1 string Prompt text
# @param -d <value> Default value if input is empty
# @param -o Optional flag (return empty if no value provided)
# @param -v <regex> Validation regex pattern
# @return 0 and prints input to stdout
tui.input() {
    local prompt=""
    local default=""
    local optional=false
    local validation=""
    local value=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d) default="$2"; shift 2 ;;
            -o) optional=true; shift ;;
            -v) validation="$2"; shift 2 ;;
            -*) shift ;; # Skip unknown flags
            *) 
                if [[ -z "$prompt" ]]; then
                    prompt="$1"
                fi
                shift
                ;;
        esac
    done

    local display_prompt="$prompt"
    [[ -n "$default" ]] && display_prompt="$display_prompt [$default]"
    display_prompt="$display_prompt: "

    while true; do
        if read -r "value?$display_prompt"; then
            # Handle default
            if [[ -z "$value" ]] && [[ -n "$default" ]]; then
                value="$default"
            fi

            # Check if empty is allowed
            if [[ -z "$value" ]]; then
                if [[ "$optional" == true ]]; then
                    echo ""
                    return 0
                else
                    continue # Loop again
                fi
            fi

            # Validation
            if [[ -n "$validation" ]]; then
                if [[ ! "$value" =~ $validation ]]; then
                    echo "❌ Invalid input (must match: $validation)" >&2
                    continue
                fi
            fi

            echo "$value"
            return 0
        else
            local read_exit=$?
            echo "" >&2 # newline after ^C or ^D
            if [[ "$optional" == true ]]; then
                echo ""
                return 0
            fi
            return $read_exit # Abort entirely when mandatory
        fi
    done
}

# @description Select exactly one item from a list.
# @param $1 string Prompt text
# @param -c Include 'Custom...' entry for free-type
# @param -p <text> fzf prompt (defaults to first argument)
# @param $@ Remaining items to select from
tui.select() {
    local prompt=""
    local custom=false
    local optional=false
    local multi=false
    local fzf_prompt=""
    local -a items=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c) custom=true; shift ;;
            -o) optional=true; shift ;;
            -m) multi=true; shift ;;
            -p) fzf_prompt="$2"; shift 2 ;;
            -*) shift ;; # Skip unknown flags
            *) 
                if [[ -z "$prompt" ]]; then
                    prompt="$1"
                else
                    items+=("$1")
                fi
                shift
                ;;
        esac
    done

    [[ -z "$fzf_prompt" ]] && fzf_prompt="$prompt"

    # Filter out empty strings from items
    items=(${items:#})

    # Handle 0 or 1 items based on optionality
    if [[ ${#items} -eq 0 ]]; then
        if [[ "$optional" == "true" ]]; then
            return 0
        else
            echo "❌ Error: Selection for '$prompt' is required but no options available." >&2
            return 1
        fi
    elif [[ ${#items} -eq 1 && "$optional" != "true" && "$custom" != "true" ]]; then
        # Auto-select the only item if required and not multi-select/custom
        if [[ "$multi" != "true" ]]; then
            echo "${items[1]}"
            return 0
        fi
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "❌ tui.select requires 'fzf' to be installed." >&2
        return 1
    fi

    local hint="(Enter: confirm"
    [[ "$multi" == true ]] && hint="(Tab: select, Enter: confirm"
    [[ "$custom" == true ]] && hint="$hint, Ctrl-N: custom"
    [[ "$optional" == true ]] && hint="$hint, Esc: skip"
    hint="$hint)"

    local items_file=""
    local input_stream=""
    local -a fzf_cmd=(fzf --prompt "$fzf_prompt $hint> " --height 40% --reverse)
    [[ "$multi" == true ]] && fzf_cmd+=(-m)

    if [[ "$custom" == true ]]; then
        # We use a temporary items file here to persist the list state so `fzf`'s internal
        # `reload()` function can update the UI dynamically when new custom elements are added
        # without closing the current selection session.
        items_file=$(mktemp)
        printf "%s\n" "${items[@]}" > "$items_file"

        local bind_cmd="ctrl-n:execute(read -r \"?Custom value: \" val < /dev/tty > /dev/tty; [[ -n \"\$val\" ]] && { printf \"%s\n\" \"\$val\" | cat - \"$items_file\" > \"${items_file}.tmp\" && mv \"${items_file}.tmp\" \"$items_file\"; })+reload(cat \"$items_file\")+first"
        
        # If multi-selection, select the new entry and move down.
        # If single-selection, immediately accept the new entry.
        if [[ "$multi" == true ]]; then
            bind_cmd="$bind_cmd+toggle+down"
        else
            bind_cmd="$bind_cmd+accept"
        fi

        fzf_cmd+=(--bind "$bind_cmd")
    else
        input_stream=$(printf "%s\n" "${items[@]}")
    fi

    while true; do
        local -a choices=()
        local fzf_exit=0
        local fzf_out=""
        
        if [[ "$custom" == true ]]; then
            fzf_out=$( "${fzf_cmd[@]}" < "$items_file" )
            fzf_exit=$?
            choices=(${(f)fzf_out})
        else
            fzf_out=$( echo "$input_stream" | "${fzf_cmd[@]}" )
            fzf_exit=$?
            choices=(${(f)fzf_out})
        fi

        # Check for explicit abort (Esc/Ctrl-C returns 130 in fzf)
        if [[ $fzf_exit -ne 0 ]]; then
            [[ -n "$items_file" ]] && rm -f "$items_file"
            if [[ "$optional" == "true" ]]; then
                return 0 # Treat Esc as a clean 'skip' when optional
            fi
            return $fzf_exit # Abort entirely when mandatory
        fi

        # User selected nothing (e.g. empty multiselect submit)
        if [[ ${#choices[@]} -eq 0 || -z "$fzf_out" ]]; then
            if [[ "$optional" == "true" ]]; then
                [[ -n "$items_file" ]] && rm -f "$items_file"
                return 0
            fi
            continue
        fi

        echo "${choices[@]}"
        [[ -n "$items_file" ]] && rm -f "$items_file"
        return 0
    done
}

# @description Select multiple items from a list.
# @param $1 string Prompt text
# @param -c Include 'Custom...' entry
# @param -o Optional 
# @param $@ Remaining items
tui.multiselect() {
    tui.select -m "$@"
}
