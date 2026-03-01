##
# Symlink a config file or directory from assets/configs/ to a destination
#
# Usage: config.symlink <source> <destination>
#
# Source is resolved like config.hydrate:
#   - First checks if it exists as an absolute/relative path
#   - Then checks in $DOTFILES/assets/configs/<source>
#
# If destination is a symlink but doesn't point to our source, replace it
# If destination is a regular file, replace it with our symlink
# If destination is a directory, error
#
# Returns: 0 on success, 1 on error
##
config.symlink() {
    local source="$1"
    local destination="$2"

    if [[ -z "$source" || -z "$destination" ]]; then
        echo "Usage: config.symlink <source> <destination>" >&2
        return 1
    fi

    # Validate and resolve source (like config.hydrate)
    if [[ -f "$source" || -d "$source" ]]; then
        : # source exists as-is
    else
        local source_alt="$DOTFILES/assets/configs/$source"
        if [[ -f "$source_alt" || -d "$source_alt" ]]; then
            source=$source_alt
        else
            echo "❌ Source not found: $1 (checked: $1, $source_alt)" >&2
            return 1
        fi
    fi

    # Resolve the absolute path of the source
    local source_abs="$(realpath "$source")"

    # Check what exists at the destination
    if [[ -d "$destination" && ! -L "$destination" ]]; then
        echo "Error: Destination is a directory: $destination" >&2
        return 1
    fi

    # If destination is already a symlink, check if it points to our source
    if [[ -L "$destination" ]]; then
        local dest_target="$(readlink -f "$destination")"
        if [[ "$dest_target" == "$source_abs" ]]; then
            # Already points to our source, nothing to do
            return 0
        else
            # Replace the symlink
            rm "$destination"
        fi
    elif [[ -e "$destination" ]]; then
        # Regular file exists, remove it
        rm "$destination"
    fi

    # Create the symlink
    ln -s "$source" "$destination"
}

config.hydrate() {
    local DOTFILES_TEMPLATES="$DOTFILES/assets/templates"
    local DOTFILES_CONFIGS="$DOTFILES/assets/configs"

    local template=$1
    shift

    # Validate template
    if [[ -z "$template" ]]; then
        echo "Usage: config.hydrate <template-path> [--config-file <path>] [--config-json <json>] [--output <path>]" >&2
        return 1
    fi

    # Check if template exists as-is
    if [[ ! -f "$template" ]]; then
        # Check if it might be a relative path in assets/templates
        local template_alt="$DOTFILES_TEMPLATES/$template"
        if [[ -f "$template_alt" ]]; then
            template=$template_alt
        else
            echo "❌ Template not found: $template" >&2
            return 1
        fi
    fi

    local merged_config='{}' output_file=

    # Parse arguments and merge configs
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config-file)
                local config_path=$2
                if [[ ! -f "$config_path" ]]; then
                    local config_alt="$DOTFILES_CONFIGS/$2"
                    if [[ -f "$config_alt" ]]; then
                        config_path=$config_alt
                    else
                        echo "❌ Config file not found: $2" >&2
                        return 1
                    fi
                fi
                merged_config=$(jq -s '.[0] * .[1]' <<< "$merged_config" < "$config_path") || return 1
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
