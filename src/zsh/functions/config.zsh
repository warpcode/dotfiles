##
# Configuration Hydration Engine
# Merges multiple JSON configs and renders a gomplate template.
#
# Usage: config.hydrate <template-path> [options]
#
# Options:
#   --config-file <path>   JSON file to merge (can be used multiple times)
#   --config-json <json>  Inline JSON to merge (can be used multiple times)
#   --output <path>       Write output to file instead of stdout
#   -h, --help            Show this help
#
# Examples:
#   config.hydrate template.yaml --config-json '{"env": "prod"}'
#   config.hydrate template.yaml --config-file base.json --config-file overrides.json --output app.conf
#
# Dependencies: jq, gomplate
#
# Returns: 0 on success, 1 on error
##
config.hydrate() {
    local template=$1
    shift

    # Validate template
    [[ -z "$template" || ! -f "$template" ]] && {
        echo "Usage: config.hydrate <template-path> [--config-file <path>] [--config-json <json>] [--output <path>]" >&2
        return 1
    }

    local merged_config='{}' output_file=

    # Parse arguments and merge configs
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config-file)
                [[ -f "$2" ]] || { echo "❌ Config file not found: $2" >&2; return 1; }
                merged_config=$(jq -s '.[0] * .[1]' <<< "$merged_config" < "$2") || return 1
                shift 2
                ;;
            --config-json)
                merged_config=$(jq -s '.[0] * $next' --argjson next "$2" <<< "$merged_config")
                shift 2
                ;;
            --output)
                output_file=$2
                shift 2
                ;;
            -h|--help)
                echo "Usage: config.hydrate <template> [--config-file <path>] [--config-json <json>] [--output <path>]"
                return 0
                ;;
            *)
                echo "❌ Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # Ensure secrets key always exists so templates referencing .secrets.* don't fail
    # Uses jq's // operator: if secrets is null/undefined, default to empty object {}
    merged_config=$(echo "$merged_config" | jq '.secrets = (.secrets // {})')

    # Write merged config to temp file for gomplate
    local tmp_config=$(mktemp /tmp/config.hydrate.XXXXXX.json)
    trap 'rm -f "$tmp_config"' EXIT INT TERM
    echo "$merged_config" > "$tmp_config"

    # Run gomplate and capture output
    local output
    output=$(gomplate -f "$template" -d "config=file://${tmp_config}?type=application/json" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Template rendering failed" >&2
        echo "$output" >&2
        return 1
    fi

    # Output to file or stdout
    [[ -n "$output_file" ]] && echo "$output" > "$output_file" || echo "$output"
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
