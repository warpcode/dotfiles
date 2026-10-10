# AI, MCP & Agent Wrapper System - Core Registries
# Thin wrappers around registry.zsh

# --- Generic Provider Executors (Reduces Eval Boilerplate) ---

_ai.provider.api_executor() {
    local pid="$1" api_path="$2"
    local api_key=$(ai.provider.credentials "$pid")
    local base_url=$(registry.get "ai_provider" "$pid" "base_url")
    ai.provider.api.base "$base_url" "$api_path" "$api_key"
}

_ai.provider.models_executor() {
    local pid="$1"
    local cached=$(df.cache get "ai" "models_${pid}")
    [[ -n "$cached" ]] && { echo "$cached"; return 0; }

    local api_func="ai.providers.${pid}.api"
    local result=$("$api_func" "/models" | jq -c -M '.data')
    if [[ -n "$result" && "$result" != "null" ]]; then
        df.cache set "ai" "models_${pid}" "$result"
    fi
    echo "$result"
}

# --- Provider ---
# Provider IDs become zsh function-name components, and provider keys become
# registry subscripts, so both are restricted to characters that are safe in
# either position. The registry (registry.zsh `_registry.validate_key`) folds
# '-' to '_' and nothing else, so '-' is the only non-alphanumeric character
# permitted here; folding it the same way keeps the registry key and the
# generated function name identical.
_ai.valid_id() {
    [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]
}
_ai.valid_key() {
    [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]
}

ai.provider.define() {
    local raw_pid="$1"
    if ! _ai.valid_id "$raw_pid"; then
        print -u2 "Error: Invalid AI provider ID '${raw_pid}'. Must contain only alphanumeric characters, underscores and dashes."
        return 1
    fi

    # Normalise exactly as the registry does: '-' becomes '_' and nothing else.
    local pid="${raw_pid//-/_}"

    local arg k
    for arg in "${@:2}"; do
        [[ "$arg" == *=* ]] || continue
        k="${arg%%=*}"
        if ! _ai.valid_key "$k"; then
            print -u2 "Error: Invalid AI provider key '${k}'. Must contain only alphanumeric characters, underscores and dashes."
            return 1
        fi
    done

    registry.define "ai_provider" "$@"

    if (( ! $+functions[ai.providers.${pid}.enabled] )); then
        functions[ai.providers.${pid}.enabled]="return 0"
    fi
    local is_openai=$(registry.get "ai_provider" "$pid" "openai_compatible")
    
    if [[ "$is_openai" == "true" || "$is_openai" == "1" ]]; then
        if (( ! $+functions[ai.providers.${pid}.api] )); then
            functions[ai.providers.${pid}.api]="_ai.provider.api_executor ${(q)pid} \"\$1\""
        fi
        
        if (( ! $+functions[ai.providers.${pid}.models] )); then
            functions[ai.providers.${pid}.models]="_ai.provider.models_executor ${(q)pid}"
        fi

        if (( ! $+functions[ai.providers.${pid}.models.free] )); then
            local target="ai.providers.${pid}.models"
            functions[ai.providers.${pid}.models.free]="${(q)target}"
        fi
    fi
}
ai.provider.list() { registry.list "ai_provider"; }

ai.provider.is_enabled() {
    registry.is_enabled "ai_provider" "${1//-/_}" "ai.providers"
}

ai.provider.credentials() {
    local pid="${1//-/_}"
    local func="ai.providers.$pid.credentials"
    (( $+functions[$func] )) && "$func"
}




# --- Generic OpenAI Compatible API Base ---
ai.provider.api.base() {
    local base_url="${1:?}"
    local api_path="${2:?}"
    local api_key="${3:-}"
    shift 3
    local extra_headers=("$@")

    local curl_args=(
        --fail --silent
        "${base_url%/}${api_path}"
        -H "Content-Type: application/json"
    )

    [[ -n "$api_key" ]] && curl_args+=(-H "Authorization: Bearer ${api_key}")

    for header in "${extra_headers[@]}"; do
        curl_args+=($header)
    done

    curl "${curl_args[@]}"
}

# --- Common Utilities ---
ai.models() {

    local pid
    local -a enabled_pids=()
    for pid in $(registry.list ai_provider); do
        _ai.valid_id "$pid" || continue
        ai.provider.is_enabled "$pid" && enabled_pids+=($pid)
    done

    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir=$(mktemp -d)
    for pid in "${enabled_pids[@]}"; do
        local func="ai.providers.$pid.models"
        if (( $+functions[$func] )); then
            (
                local raw_models=$("$func" 2>/dev/null)
                if [[ -z "$raw_models" || "$raw_models" == "null" ]]; then
                    print -r -- "[]" > "$tmp_dir/$pid.json"
                elif jq -e . >/dev/null 2>&1 <<< "$raw_models"; then
                    print -r -- "$raw_models" > "$tmp_dir/$pid.json"
                else
                    print -r -- "[]" > "$tmp_dir/$pid.json"
                fi
            ) &
        fi
    done
    wait

    [[ -n "$restore_monitor" ]] && setopt monitor

    local output
    if ls "$tmp_dir"/*.json >/dev/null 2>&1; then
        output=$(jq -n -c 'reduce inputs as $i ({}; . + { (input_filename | sub(".*/"; "") | sub(".json$"; "")): $i })' "$tmp_dir"/*.json 2>/dev/null)
    fi
    rm -rf "$tmp_dir"

    if [[ -n "$output" && "$output" != "null" ]]; then
        echo "$output" | jq -c -M .
    else
        echo "{}"
    fi
}

ai.models.free() {
    local pid
    local -a enabled_pids=()
    for pid in $(registry.list ai_provider); do
        _ai.valid_id "$pid" || continue
        ai.provider.is_enabled "$pid" && enabled_pids+=($pid)
    done

    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir=$(mktemp -d)
    for pid in "${enabled_pids[@]}"; do
        [[ "$(registry.get ai_provider "$pid" openai_compatible)" == "true" ]] || continue
        local free_func="ai.providers.$pid.models.free"
        (( $+functions[$free_func] )) || continue

        (
            local raw name base_url api_key_env
            raw=$("$free_func" 2>/dev/null)
            [[ -z "$raw" || "$raw" == "null" || "$raw" == "[]" ]] && exit 0
            jq -e . >/dev/null 2>&1 <<< "$raw" || exit 0

            name="$(registry.get ai_provider "$pid" name)"
            base_url="$(registry.get ai_provider "$pid" base_url)"
            api_key_env="$(registry.get ai_provider "$pid" api_key_env)"

            jq -n \
                --arg pid "$pid" --arg name "$name" \
                --arg base_url "$base_url" --arg key_env "$api_key_env" \
                --argjson models "$raw" \
                '{
                    ($pid): {
                        name: $name,
                        npm: "@ai-sdk/openai-compatible",
                        options: ({baseURL: $base_url} + (if $key_env != "" then {apiKey: ("{env:" + $key_env + "}")} else {} end)),
                        models: (reduce $models[] as $m ({}; .[$m.id] = {name: ($m.name // $m.id)}))
                    }
                }' > "$tmp_dir/$pid.json" 2>/dev/null || exit 0
        ) &
    done
    wait

    [[ -n "$restore_monitor" ]] && setopt monitor

    local output
    if ls "$tmp_dir"/*.json >/dev/null 2>&1; then
        output=$(jq -n -c 'reduce inputs as $i ({}; . + $i)' "$tmp_dir"/*.json 2>/dev/null)
    fi
    rm -rf "$tmp_dir"

    if [[ -n "$output" && "$output" != "null" ]]; then
        echo "$output" | jq -c -M .
    else
        echo "{}"
    fi
}



# ai.chat <provider>/<model> [prompt]
# Example: ai.chat opencode/big-pickle "Hello"
ai.chat() {
    local target="${1:?Usage: ai.chat <provider>/<model> [prompt]}"
    shift
    local provider="${target%%/*}"
    local model="${target#*/}"
    local prompt="$*"

    if ! _ai.valid_id "$provider"; then
        print -u2 "Error: Invalid AI provider ID '${provider}'."
        return 1
    fi

    # Normalise exactly as the registry does: '-' becomes '_' and nothing else.
    local pid="${provider//-/_}"

    # 1. Get Provider Details
    local base_url=$(registry.get "ai_provider" "$pid" "base_url")
    [[ -z "$base_url" ]] && { print "Unknown provider: $provider" >&2; return 1; }

    # 2. Get Credentials
    local api_key=$(ai.provider.credentials "$pid")

    # 3. Handle Input (Piped + Args)
    local input=""
    [[ ! -t 0 ]] && input=$(cat)
    local content="$prompt"
    [[ -n "$input" ]] && content="${prompt}${prompt:+: }${input}"
    [[ -z "$content" ]] && { print "Error: No prompt provided via arguments or pipe." >&2; return 1; }

    # 4. Execute via OpenAI Base API
    ai.provider.api.base "$base_url" "/chat/completions" "$api_key" \
        -d @- <<EOF | jq -r '.choices[0].message.content'
{
  "model": "$model",
  "messages": [
    {
      "role": "user",
      "content": $(jq -Rs . <<< "$content")
    }
  ],
  "stream": false
}
EOF
}
