##
# Configuration Hydration Engine
# Merges base configs with templates and injects secrets using gomplate.
# Prints the rendered template to stdout.
##

config.hydrate() {
    local tool=$1
    if [[ -z "$tool" ]]; then
        echo "Usage: config.hydrate <tool_name> [key=value ...]" >&2
        return 1
    fi
    shift

    local template_dir="${DOTFILES}/assets/templates"
    local config_dir="${DOTFILES}/assets/configs"

    # Find template (support .json.tmpl, .yaml.tmpl, .tmpl)
    local template=$(ls ${template_dir}/${tool}.*tmpl(N) | head -1)
    if [[ -z "$template" ]]; then
        echo "❌ No template found for '$tool' in $template_dir" >&2
        return 1
    fi

    # Find base config (optional)
    local base_config=$(ls ${config_dir}/${tool}.{json,yaml,yml}(N) | head -1)

    # Ensure gomplate is available and run it via mise
    local gomplate_cmd=("gomplate")
    if (( $+commands[mise] )); then
        gomplate_cmd=("mise" "exec" "--" "gomplate")
    fi

    local gomplate_args=("-f" "${template}")
    local -a env_args=()

    if [[ -n "$base_config" ]]; then
        gomplate_args+=("-d" "config=file://${base_config}")
    else
        # Provide an empty object as default so templates can use (ds "config").key | default "..."
        env_args+=("HYDRATE_EMPTY_CONFIG={}")
        gomplate_args+=("-d" "config=env:HYDRATE_EMPTY_CONFIG?type=application/json")
    fi
    # Process extra args as datasources (key=value)
    for arg in "$@"; do
        if [[ "$arg" == *=* ]]; then
            local key="${arg%%=*}"
            local val="${arg#*=}"
            local env_var="HYDRATE_DATA_${key}"

            # Add to environment for the gomplate command
            env_args+=("${env_var}=${val}")

            # Detect if it's JSON and use the env: scheme
            if [[ "$val" =~ ^[{\[] ]]; then
                gomplate_args+=("-d" "${key}=env:${env_var}?type=application/json")
            else
                gomplate_args+=("-d" "${key}=env:${env_var}")
            fi
        fi
    done

    if env "${env_args[@]}" "${gomplate_cmd[@]}" "${gomplate_args[@]}"; then
        return 0
    else
        echo "❌ Failed to hydrate configuration for '$tool'" >&2
        return 1
    fi
}
