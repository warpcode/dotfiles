# OpenCode CLI

alias ai.code='ai.opencode'

ai.opencode() {
    local model="opencode/glm-4.7-free"

    if [[ "$IS_WORK" == "1" ]]; then
        local git_user
        git_user=$(git config user.name 2>/dev/null || echo "")
        if [[ "${git_user:l}" != "warpcode" ]]; then
            model="github-copilot/gpt-5-mini"
        fi
    fi

    OPENCODE_MODEL="$model" npx -y opencode-ai@latest "$@"
}

ai.opencode.configure.litellm() {
    local models=($(ai.providers.litellm.models))
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to fetch models from LiteLLM API" >&2
        return 1
    fi

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

    local models_json="{}"
    for model in "${models[@]}"; do
        models_json=$(echo "$models_json" | jq --arg model "$model" '. + {($model): {name: ($model + " (via LiteLLM)")}}')
    done

    if jq --argjson new_models "$models_json" '.provider.litellm.models = $new_models' "$config_file" > "${config_file}.tmp"; then
        mv "${config_file}.tmp" "$config_file"
        echo "✅ Updated LiteLLM models section"
    else
        echo "❌ Failed to update configuration" >&2
        return 1
    fi
}
