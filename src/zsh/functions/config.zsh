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
