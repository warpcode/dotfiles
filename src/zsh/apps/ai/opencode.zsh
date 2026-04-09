# OpenCode configuration generator

# Creates a bare config file only if one does not already exist.
opencode.configure.base() {
    local target="${1:-generic/.config/opencode/opencode.json}"
    [[ -f "$target" ]] && return 0
    mkdir -p "${target:h}"
    jq -n '{
        "$schema": "https://opencode.ai/config.json",
        permission: {external_directory: "allow", skill: "allow"},
        instructions: ["CRUSH.md","GEMINI.md","docs/guidelines.md",".cursor/rules/*.md","AI.md",".github/copilot-instructions.md"],
        mcp: {},
        model: "{env:OPENCODE_MODEL}",
        plugin: ["oh-my-openagent@latest"],
        provider: {}
    }' > "$target"
}

# Rebuilds the provider block from enabled registry providers (free models only).
# Also updates .model to the highest-priority free model found.
opencode.configure.providers() {
    local target="${1:-generic/.config/opencode/opencode.json}"
    local providers selected_model='' pid

    providers="$(ai.models.free)"

    local sorted_pids pid_priority
    sorted_pids=$(for pid in $(echo "$providers" | jq -r 'keys[]'); do
        pid_priority="$(registry.get ai_provider "$pid" priority)"
        echo "${pid_priority:-999} $pid"
    done | sort -n | awk '{print $2}')

    for pid in ${(f)sorted_pids}; do
        local m
        m="$(jq -r --arg p "$pid" '.[$p].models | keys_unsorted[0] // empty' <<<"$providers")"
        [[ -n "$m" ]] && { selected_model="$pid/$m"; break; }
    done

    local tmp
    tmp="$(jq \
        --argjson providers "$providers" \
        --arg model "$selected_model" '
        .provider = $providers | (if $model != "" then .model = $model else . end)
    ' "$target")" && printf '%s\n' "$tmp" > "$target"
}

# Rebuilds the mcp block from enabled registry MCP recipes.
opencode.configure.mcps() {
    local target="${1:-generic/.config/opencode/opencode.json}"
    local tmp
    tmp="$(jq --argjson mcps "$(ai.mcps)" '.mcp = $mcps' "$target")" && printf '%s\n' "$tmp" > "$target"
}

# Orchestrates a full config regeneration: base → providers → mcps.
opencode.configure() {
    local target="${1:-generic/.config/opencode/opencode.json}"
    opencode.configure.base "$target"
    opencode.configure.providers "$target"
    opencode.configure.mcps "$target"
}
