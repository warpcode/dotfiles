ai.litellm.models() {
    if ! curl --fail -s "$LITELLM_API_ENDPOINT/models" -H "Authorization: Bearer $LITELLM_API_KEY" -H "Content-Type: application/json" | jq -r ".data[].id" 2>/dev/null; then
        echo "❌ Failed to fetch LiteLLM models from $LITELLM_API_ENDPOINT" >&2
        return 1
    fi
}

ai.opencode.configure.litellm() {
    # Fetch models from LiteLLM API
    local models=($(ai.litellm.models))
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to fetch models from LiteLLM API" >&2
        return 1
    fi
    
    # Check if models array is empty or contains only empty strings
    local non_empty_models=()
    for model in "${models[@]}"; do
        if [[ -n "$model" ]]; then
            non_empty_models+=("$model")
        fi
    done
    
    if [[ ${#non_empty_models[@]} -eq 0 ]]; then
        echo "❌ No models available from LiteLLM API" >&2
        return 1
    fi
    
    models=("${non_empty_models[@]}")

    local config_file="$DOTFILES/generic/.config/opencode/opencode.json"



    # Build new models JSON with "(via LiteLLM)" suffix
    local models_json="{}"
    for model in "${models[@]}"; do
        models_json=$(echo "$models_json" | jq --arg model "$model" '. + {($model): {name: ($model + " (via LiteLLM)")}}')
    done

    # Update ONLY the models section
    if jq --argjson new_models "$models_json" '.provider.litellm.models = $new_models' "$config_file" > "${config_file}.tmp"; then
        mv "${config_file}.tmp" "$config_file"
        echo "✅ Updated LiteLLM models section"
    else
        echo "❌ Failed to update configuration" >&2
        return 1
    fi
}
