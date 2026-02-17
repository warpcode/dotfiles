##
# Configuration Hydration Engine
# Pure function: Template + Config Data → Rendered Output
# Usage: config.hydrate <template-path> [--config-file <path>] [--config-json <json>] [--output <path>]
##

config.hydrate() {
    local template=$1
    shift

    if [[ -z "$template" || ! -f "$template" ]]; then
        echo "Usage: config.hydrate <template-path> [--config-file <path>] [--config-json <json>] [--output <path>]" >&2
        return 1
    fi

    # Accumulate merged config incrementally
    local merged_config="{}"
    local output_file=""

    # Parse arguments and deep merge configs
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config-file)
                if [[ -f "$2" ]]; then
                    merged_config=$(jq -s '.[0] * .[1]' <<< "$merged_config $(cat "$2")")
                else
                    echo "❌ Config file not found: $2" >&2
                    return 1
                fi
                shift 2
                ;;
            --config-json)
                merged_config=$(jq -s '.[0] * $next' --argjson next "$2" <<< "$merged_config")
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                echo "❌ Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # Ensure secrets field exists (templates may reference it)
    merged_config=$(echo "$merged_config" | jq '.secrets = (.secrets // {})')

    # Write merged config to temp file for gomplate (use absolute path)
    local tmp_config=$(mktemp /tmp/config.hydrate.XXXXXX.json)
    echo "$merged_config" > "$tmp_config"

    # Run gomplate with absolute path to temp config
    # Capture both stdout and stderr, then process
    local output stderr_output
    output=$(gomplate -f "$template" -d "config=file://${tmp_config}?type=application/json" 2>&1)
    local exit_code=$?

    rm -f "$tmp_config"

    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Template rendering failed" >&2
        echo "$output" >&2
        return 1
    fi

    # Output or write to file
    if [[ -n "$output_file" ]]; then
        echo "$output" > "$output_file"
    else
        echo "$output"
    fi
}

##
# Replace content between two markers in a file.
# If markers don't exist, appends them with replacement.
# If file doesn't exist, creates it with markers and replacement.
#
# Usage: config.markers.replace <file> <lead_marker> <tail_marker> <replacement>
# Args:
#   target_file   - Path to file to modify
#   lead          - Opening marker (regex)
#   tail          - Closing marker (regex)
#   replacement   - Text to insert between markers
##
config.markers.replace() {
    local target_file="$1" lead="$2" tail="$3" replacement="$4"

    # Validate arguments
    [[ -z "$target_file" || -z "$lead" || -z "$tail" || -z "$replacement" ]] && return 1

    # Create new file with markers if it doesn't exist
    if [[ ! -f "$target_file" ]]; then
        printf '%s\n%s\n%s\n' "$lead" "$replacement" "$tail" > "$target_file"
        return
    fi

    # Only append if BOTH markers are missing
    if ! grep -qE -- "$lead" "$target_file" || ! grep -qE -- "$tail" "$target_file"; then
        printf '%s\n%s\n%s\n' "$lead" "$replacement" "$tail" >> "$target_file"
        return
    fi

    # Replace content between markers
    awk -v lead="$lead" -v tail="$tail" -v repl="$replacement" '
        $0 ~ lead { print; print repl; in_block=1; next }
        in_block && $0 ~ tail { in_block=0; print; next }
        !in_block' "$target_file" > "${target_file}.tmp" &&
        mv "${target_file}.tmp" "$target_file"
}
