ai.litellm.models() {
    local raw_models
    raw_models=$(curl --fail -s "$LITELLM_API_ENDPOINT/models" \
        -H "Authorization: Bearer $LITELLM_API_KEY" \
        -H "Content-Type: application/json" | jq -r ".data[].id" 2>/dev/null)

    if [[ $? -ne 0 || -z "$raw_models" ]]; then
        echo "❌ Failed to fetch LiteLLM models from $LITELLM_API_ENDPOINT" >&2
        return 1
    fi

    # Filter out models matching name/* and those ending with -YYYY-MM-DD
    local filtered_models
    filtered_models=$(echo "$raw_models" \
        | grep -vE "^[^/]+/\*$" \
        | grep -vE "\-[0-9]{4}\-?[0-9]{2}\-?[0-9]{2}(:[^:]+)?$" \
        | grep -vE "\-[0-9]{2}\-202[0-9](:[^:]+)?$" \
        | grep -vE "\-[0-9]{2}\-[0-9]{2}(:[^:]+)?$" \
        | grep -vE "\-preview(\-|$)" )

    # Separate and sort: models without "/" prefix first (original order), then models with "/" prefix sorted
    local non_prefixed_models prefixed_models
    non_prefixed_models=$(echo "$filtered_models" | grep -v '/')
    prefixed_models=$(echo "$filtered_models" | grep '/' | sort)

    echo "$non_prefixed_models"
    echo "$prefixed_models"
}

ai.openrouter.models.free() {
    if [[ -z "$OPENROUTER_API_KEY" ]]; then
        echo "❌ OPENROUTER_API_KEY is not set" >&2
        return 1
    fi

    local raw_models
    raw_models=$(curl --fail -s "https://openrouter.ai/api/v1/models" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" | jq -r '.data[] | select(.pricing.prompt == "0" and .pricing.completion == "0") | .id' 2>/dev/null)

    if [[ $? -ne 0 || -z "$raw_models" ]]; then
        echo "❌ Failed to fetch free OpenRouter models" >&2
        return 1
    fi

    echo "$raw_models"
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
