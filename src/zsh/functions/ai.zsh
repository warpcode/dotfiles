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

    local result=$(ai.providers.${pid}.api "/models" | jq -c -M '.data')
    if [[ -n "$result" && "$result" != "null" ]]; then
        df.cache set "ai" "models_${pid}" "$result"
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


# --- Skills ---
ai.skills.install() {
    local agent="${1:-universal}"
    local dotfiles_dir="${DOTFILES:-${HOME}/.dotfiles}"
    local skills_file="${dotfiles_dir}/.chezmoidata/skills.json"

    if [[ ! -f "$skills_file" ]]; then
        tui.warn "Skills manifest not found: $skills_file"
        return 0
    fi

    tui.task "Configuring ai-skills for agent: $agent"
    tui.indent.push
    {
        (( $+commands[jq] )) || { tui.warn "jq command not found, skipping"; return 0; }
        (( $+commands[npx] )) || { tui.warn "npx command not found, skipping"; return 0; }

        local repo skills_str out full_repo name
        local -a name_args

        while IFS=$'\t' read -r repo skills_str; do
            [[ -z "$repo" ]] && continue

            # Handle relative local directories by prepending DOTFILES.
            full_repo="$repo"
            if [[ "$repo" == ./* ]]; then
                local rel_path="${repo#./}"
                full_repo="${dotfiles_dir}/${rel_path}"
            fi

            name_args=()
            if [[ -z "$skills_str" || "$skills_str" == "*" ]]; then
                tui.step "Skills: * (${repo}) for ${agent}"
            else
                for name in ${(s:,:)skills_str}; do
                    name_args+=(--skill "$name")
                done
                tui.step "Skills: ${skills_str} (${repo}) for ${agent}"
            fi

            if ! out=$(npx -y skills add "$full_repo" "${name_args[@]}" -g --agent "$agent" -y < /dev/null 2>&1); then
                tui.error "Failed to install ${repo}"
                echo "$out" | grep -v "█"
            fi
        done < <(jq -r '.skills[]? | "\(.repo)\t\((.skills // []) | join(","))"' "$skills_file")

        tui.success "Configuration complete for $agent"
    } always {
        tui.indent.pop
    }
}
