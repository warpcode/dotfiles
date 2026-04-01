# AI, MCP & Agent Wrapper System - Core Registries
# Inspired by pkg.zsh

# --- Provider Registry ---
typeset -gA ai_providers ai_provider_exists
typeset -ga ai_provider_list

ai.define_provider() {
    local pid="${1//-/_}"; shift
    (( ! ${ai_provider_exists[$pid]:-0} )) && { ai_provider_list+=($pid); ai_provider_exists[$pid]=1 }
    local pair k v
    for pair in "$@"; do
        k="${pair%%=*}" v="${pair#*=}"
        ai_providers[$pid:$k]="$v"
    done
}

ai.provider.load_all() {
    local base; base=$(fs.dotfiles.path "src/zsh/apps/ai/providers") || return 1
    local f; for f in "$base/"*.zsh(N); do source "$f"; done
}

ai.provider.is_enabled() {
    local pid="${1//-/_}"
    
    # 1. Check if explicitly disabled/enabled via function
    local func="ai.providers.$pid.enabled"
    if (( $+functions[$func] )); then
        "$func" || return 1
    fi
    
    # 2. Check for required key
    if [[ "${ai_providers[$pid:requires_key]}" == "1" ]]; then
        ai.provider.has_credentials "$pid" || return 1
    fi
    
    return 0
}

ai.provider.has_credentials() {
    local pid="${1//-/_}"
    
    # Delegate to custom function if it exists
    local func="ai.providers.$pid.has_credentials"
    if (( $+functions[$func] )); then
        "$func"
        return $?
    fi

    # Default logic: check for environment variable
    # We look at the credentials function to see what it returns
    # but that might be expensive. Instead, we'll assume standard naming
    # or rely on the provider to implement its own has_credentials.
    
    # For now, let's just try to get the credentials.
    # To avoid repeated expensive calls, we'll check if it's already in the environment.
    local key=$(ai.provider.get_credentials "$pid" 2>/dev/null)
    [[ -n "$key" ]] && return 0
    
    return 1
}

ai.provider.get_credentials() {
    local pid="${1//-/_}"
    local func="ai.providers.$pid.credentials"
    (( $+functions[$func] )) && "$func"
}

# --- MCP Recipe Registry ---
typeset -gA ai_mcp_recipes ai_mcp_recipe_exists
typeset -ga ai_mcp_recipe_list

ai.mcp.define_recipe() {
    local rid="${1//-/_}"; shift
    (( ! ${ai_mcp_recipe_exists[$rid]:-0} )) && { ai_mcp_recipe_list+=($rid); ai_mcp_recipe_exists[$rid]=1 }
    local pair k v
    for pair in "$@"; do
        k="${pair%%=*}" v="${pair#*=}"
        ai_mcp_recipes[$rid:$k]="$v"
    done
}

ai.mcp.recipe.load_all() {
    local base; base=$(fs.dotfiles.path "src/zsh/apps/ai/mcp/recipes") || return 1
    local f; for f in "$base/"*.zsh(N); do source "$f"; done
}

ai.mcp.recipe.is_enabled() {
    local rid="${1//-/_}"
    local func="ai.mcp.recipes.$rid.enabled"
    if (( $+functions[$func] )); then
        "$func"
        return $?
    fi
    return 0
}

ai.mcp.recipe.get_config() {
    local rid="${1//-/_}"
    local -A config
    config[command]="${ai_mcp_recipes[$rid:command]}"
    config[type]="${ai_mcp_recipes[$rid:type]:-local}"
    config[url]="${ai_mcp_recipes[$rid:url]}"
    local func="ai.mcp.recipes.$rid.config"
    (( $+functions[$func] )) && "$func"
}

# --- Agent/Task Registry ---
typeset -gA ai_agents ai_agent_exists
typeset -ga ai_agent_list

ai.define_agent() {
    local aid="${1//-/_}"; shift
    (( ! ${ai_agent_exists[$aid]:-0} )) && { ai_agent_list+=($aid); ai_agent_exists[$aid]=1 }
    local pair k v
    for pair in "$@"; do
        k="${pair%%=*}" v="${pair#*=}"
        ai_agents[$aid:$k]="$v"
    done
}

ai.agent.load_all() {
    local base; base=$(fs.dotfiles.path "src/zsh/apps/ai/agents/definitions") || return 1
    local f; for f in "$base/"*.zsh(N); do source "$f"; done
}

ai.agent.get_details() {
    local aid="${1//-/_}"
    local -A details
    details[name]="${ai_agents[$aid:name]}"
    details[description]="${ai_agents[$aid:description]}"
    details[type]="${ai_agents[$aid:type]:-subagent}"
    details[mcp_tools]="${ai_agents[$aid:mcp_tools]}"
    details[skills]="${ai_agents[$aid:skills]}"
    details[internal_tools]="${ai_agents[$aid:internal_tools]}"
    details[commands]="${ai_agents[$aid:commands]}"
    details[task_type]="${ai_agents[$aid:task_type]}"
    local func="ai.agents.$aid.details"
    (( $+functions[$func] )) && "$func"
}

# --- Common Utilities ---
ai.models() {
    local force="${1:-0}"
    local cached=$(cache.get "ai" "models_all")
    [[ "$force" != "1" && -n "$cached" ]] && { echo "$cached"; return 0; }

    ai.provider.load_all

    local pid
    local -a enabled_pids=()
    for pid in "${ai_provider_list[@]}"; do
        ai.provider.is_enabled "$pid" && enabled_pids+=($pid)
    done

    # Suppress job control notifications
    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir=$(mktemp -d)
    for pid in "${enabled_pids[@]}"; do
        (
            local func="ai.providers.$pid.models"
            if (( $+functions[$func] )); then
                local raw_models=$("$func" 2>/dev/null)
                # Sanitize and validate JSON output
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

    # Consolidate results using jq
    local output
    if ls "$tmp_dir"/*.json >/dev/null 2>&1; then
        # Use -c to keep it compact for the variable, we pretty-print at the end
        output=$(jq -n -c 'reduce inputs as $i ({}; . + { (input_filename | sub(".*/"; "") | sub(".json$"; "")): $i })' "$tmp_dir"/*.json 2>/dev/null)
    fi
    rm -rf "$tmp_dir"

    if [[ -n "$output" && "$output" != "null" ]]; then
        # Pretty print for the user and cache
        local pretty_output=$(echo "$output" | jq -M .)
        cache.set "ai" "models_all" "$pretty_output"
        echo "$pretty_output"
    else
        echo "{}"
    fi
    }
ai.models.free() {
    local force="${1:-0}"
    local cached=$(cache.get "ai" "models_free")
    [[ "$force" != "1" && -n "$cached" ]] && { echo "$cached"; return 0; }

    ai.provider.load_all

    local pid
    local -a enabled_pids=()
    for pid in "${ai_provider_list[@]}"; do
        ai.provider.is_enabled "$pid" && enabled_pids+=($pid)
    done

    # Suppress job control notifications
    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir=$(mktemp -d)
    for pid in "${enabled_pids[@]}"; do
        (
            local free_func="ai.providers.$pid.models.free"
            if (( $+functions[$free_func] )); then
                local raw_models=$("$free_func" 2>/dev/null)
                # Sanitize and validate JSON output
                local clean_models=$(echo "$raw_models" | jq -c -M . 2>/dev/null)
                if [[ -z "$clean_models" || "$clean_models" == "null" ]]; then
                    clean_models="[]"
                fi
                print -r -- "$clean_models" > "$tmp_dir/$pid.json"
            else
                # Skip providers that don't explicitly support free model detection
                echo "[]" > "$tmp_dir/$pid.json"
            fi
        ) &
    done
    wait

    [[ -n "$restore_monitor" ]] && setopt monitor

    # Consolidate results using jq
    local output
    if ls "$tmp_dir"/*.json >/dev/null 2>&1; then
        # Use -c to keep it compact for the variable, we pretty-print at the end
        output=$(jq -n -c 'reduce inputs as $i ({}; . + { (input_filename | sub(".*/"; "") | sub(".json$"; "")): $i })' "$tmp_dir"/*.json 2>/dev/null)
    fi
    rm -rf "$tmp_dir"

    if [[ -n "$output" && "$output" != "null" ]]; then
        # Pretty print for the user and cache
        local pretty_output=$(echo "$output" | jq -M .)
        cache.set "ai" "models_free" "$pretty_output"
        echo "$pretty_output"
    else
        echo "{}"
    fi
}
