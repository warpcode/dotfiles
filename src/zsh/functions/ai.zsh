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
    local cached=$(cache.get "ai" "models_${pid}")
    [[ -n "$cached" ]] && { echo "$cached"; return 0; }

    local result=$(ai.providers.${pid}.api "/models" | jq -c -M '.data')
    if [[ -n "$result" && "$result" != "null" ]]; then
        cache.set "ai" "models_${pid}" "$result"
    fi
    echo "$result"
}

# --- Provider ---
ai.provider.define() {
    registry.define "ai_provider" "$@"
    
    local pid="${1//-/_}"
    if (( ! $+functions[ai.providers.${pid}.enabled] )); then
        eval "ai.providers.${pid}.enabled() { return 0 }"
    fi
    local is_openai=$(registry.get "ai_provider" "$pid" "openai_compatible")
    
    if [[ "$is_openai" == "true" || "$is_openai" == "1" ]]; then
        if (( ! $+functions[ai.providers.${pid}.api] )); then
            eval "ai.providers.${pid}.api() { _ai.provider.api_executor '$pid' \"\$1\"; }"
        fi
        
        if (( ! $+functions[ai.providers.${pid}.models] )); then
            eval "ai.providers.${pid}.models() { _ai.provider.models_executor '$pid'; }"
        fi

        if (( ! $+functions[ai.providers.${pid}.models.free] )); then
            eval "ai.providers.${pid}.models.free() { ai.providers.${pid}.models; }"
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

# --- MCP ---
ai.mcp.define() {
    registry.define "ai_mcp_recipe" "$@"
    local id="${1//-/_}"
    if (( ! $+functions[ai.mcps.${id}.enabled] )); then
        eval "ai.mcps.${id}.enabled() { return 0 }"
    fi
}
ai.mcp.is_enabled() { registry.is_enabled "ai_mcp_recipe" "${1//-/_}" "ai.mcps" }
ai.mcp.get() { registry.get "ai_mcp_recipe" "$1" "$2"; }

# --- Agent ---
ai.agent.define() {
    registry.define "ai_agent" "$@"
    local id="${1//-/_}"
    if (( ! $+functions[ai.agents.${id}.enabled] )); then
        eval "ai.agents.${id}.enabled() { return 0 }"
    fi
}

ai.agent.get() { registry.get "ai_agent" "$1" "$2"; }

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
        ai.provider.is_enabled "$pid" && enabled_pids+=($pid)
    done

    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir=$(mktemp -d)
    for pid in "${enabled_pids[@]}"; do
        (
            local func="ai.providers.$pid.models"
            if (( $+functions[$func] )); then
                local raw_models=$("$func" 2>/dev/null)
                local clean_models=$(echo "$raw_models" | jq -c -M . 2>/dev/null)
                if [[ -z "$clean_models" || "$clean_models" == "null" ]]; then
                    clean_models="[]"
                fi
                print -r -- "$clean_models" > "$tmp_dir/$pid.json"
            fi
        ) &
    done
    wait

    [[ -n "$restore_monitor" ]] && setopt monitor

    local output
    if ls "$tmp_dir"/*.json >/dev/null 2>&1; then
        output=$(jq -n -c 'reduce inputs as $i ({}; . + { (input_filename | sub(".*/"; "") | sub(".json$"; "")): $i })' "$tmp_dir"/*.json 2>/dev/null)
    fi
    rm -rf "$tmp_dir"

    if [[ -n "$output" && "$output" != "null" ]]; then
        echo "$output" | jq -M .
    else
        echo "{}"
    fi
}

ai.models.free() {
    local pid
    local -a enabled_pids=()
    for pid in $(registry.list ai_provider); do
        ai.provider.is_enabled "$pid" && enabled_pids+=($pid)
    done

    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir=$(mktemp -d)
    for pid in "${enabled_pids[@]}"; do
        (
            local free_func="ai.providers.$pid.models.free"
            if (( $+functions[$free_func] )); then
                local raw_models=$("$free_func" 2>/dev/null)
                local clean_models=$(echo "$raw_models" | jq -c -M . 2>/dev/null)
                if [[ -z "$clean_models" || "$clean_models" == "null" ]]; then
                    clean_models="[]"
                fi
                print -r -- "$clean_models" > "$tmp_dir/$pid.json"
            else
                echo "[]" > "$tmp_dir/$pid.json"
            fi
        ) &
    done
    wait

    [[ -n "$restore_monitor" ]] && setopt monitor

    local output
    if ls "$tmp_dir"/*.json >/dev/null 2>&1; then
        output=$(jq -n -c 'reduce inputs as $i ({}; . + { (input_filename | sub(".*/"; "") | sub(".json$"; "")): $i })' "$tmp_dir"/*.json 2>/dev/null)
    fi
    rm -rf "$tmp_dir"

    if [[ -n "$output" && "$output" != "null" ]]; then
        echo "$output" | jq -M .
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

    # Normalize provider name for registry/function lookups
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

