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
            [[ "$(registry.get ai_provider "$pid" openai_compatible)" == "true" ]] || exit 0
            local free_func="ai.providers.$pid.models.free"
            (( $+functions[$free_func] )) || exit 0

            local raw raw_models name base_url api_key_env
            raw=$("$free_func" 2>/dev/null)
            raw_models=$(echo "$raw" | jq -c -M . 2>/dev/null)
            [[ -z "$raw_models" || "$raw_models" == "null" || "$raw_models" == "[]" ]] && exit 0

            name="$(registry.get ai_provider "$pid" name)"
            base_url="$(registry.get ai_provider "$pid" base_url)"
            api_key_env="$(registry.get ai_provider "$pid" api_key_env)"

            jq -n \
                --arg pid "$pid" --arg name "$name" \
                --arg base_url "$base_url" --arg key_env "$api_key_env" \
                --argjson models "$raw_models" \
                '{
                    ($pid): {
                        name: $name,
                        npm: "@ai-sdk/openai-compatible",
                        options: ({baseURL: $base_url} + (if $key_env != "" then {apiKey: ("{env:" + $key_env + "}")} else {} end)),
                        models: (reduce $models[] as $m ({}; .[$m.id] = {name: ($m.name // $m.id)}))
                    }
                }' > "$tmp_dir/$pid.json"
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
        echo "$output" | jq -M .
    else
        echo "{}"
    fi
}

ai.mcps() {
    local format="${1:-opencode}"
    local rid mcp_list='[]'
    
    for rid in $(registry.list ai_mcp_recipe); do
        ai.mcp.is_enabled "$rid" || continue

        local _type='' _cmd='' _url='' _header_env='' _desc='' _env_vars=''
        _type="$(ai.mcp.get "$rid" type)"
        _cmd="$(ai.mcp.get "$rid" command)"
        _url="$(ai.mcp.get "$rid" url)"
        _header_env="$(ai.mcp.get "$rid" api_key_header)"
        _desc="$(ai.mcp.get "$rid" description)"
        _env_vars="$(ai.mcp.get "$rid" env)" 

        # Reliably split command into parts using Zsh's shell parser
        local -a _parts=() _dequoted=()
        _parts=(${(z)_cmd})
        for _p in "${_parts[@]}"; do
            local _p="$_p"
            _dequoted+=("${(Q)_p}")
        done
        
        local _cmd_json='[]'
        if [[ ${#_dequoted} -gt 0 ]]; then
            _cmd_json=$(jq -n -c '$ARGS.positional' --args -- "${_dequoted[@]}")
        fi

        mcp_list="$(jq -n --argjson m "$mcp_list" --arg k "$rid" \
            --arg t "$_type" --argjson cp "$_cmd_json" --arg u "$_url" --arg h "$_header_env" --arg d "$_desc" --arg e "$_env_vars" \
            '$m + [{
                id: $k,
                type: $t,
                command: ($cp[0] // null),
                args: ($cp[1:] // []),
                full_command: $cp,
                url: $u,
                description: $d,
                env: (
                    (if $h != "" then {($h): ("{env:" + $h + "}")} else {} end) +
                    (if $e != "" then ($e | split(",") | map( (index(":") // length) as $i | {key: .[0:$i], value: .[$i+1:]} ) | from_entries) else {} end)
                )
            }]')"
    done

    # Normalize format for template selection
    local template_format="$format"
    case "$format" in
        antigravity|claude|cursor) template_format="antigravity" ;;
        opencode|*) template_format="opencode" ;;
    esac

    local template="ai/mcp/${template_format}.json.tmpl"
    config.hydrate "$template" --config-json "$(jq -n --argjson m "$mcp_list" '{mcps: $m}')"
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

