pkg.recipe.define opencode \
    managers="npm" \
    npm="opencode-ai@latest"


pkg.recipe.opencode.configure() {
    tui.task "Configuring opencode..."
    tui.indent.push
    {
        (( $+commands[opencode] )) || { tui.warn "opencode command not found, skipping"; return 0; }
        (( $+commands[jq] )) || { tui.warn "jq command not found, skipping"; return 0; }

        local target="${DOTFILES}/generic/.config/opencode/opencode.json"
        tui.step "Updating $target"
        pkg.recipe.opencode.configure.base "$target"
        pkg.recipe.opencode.configure.providers "$target"
        pkg.recipe.opencode.configure.mcps "$target"
        tui.success "Configuration complete"
    } always {
        tui.indent.pop
    }
}

pkg.recipe.opencode.configure.base() {
    local target="${1:-${DOTFILES}/generic/.config/opencode/opencode.json}"
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

pkg.recipe.opencode.configure.providers() {
    local target="${1:-${DOTFILES}/generic/.config/opencode/opencode.json}"
    local providers selected_model='' pid

    providers="$(ai.models.free)"

    local sorted_pids pid_priority
    sorted_pids=$(for pid in $(echo "$providers" | jq -r 'keys[]'); do
        pid_priority="$(registry.get ai_provider "$pid" priority)"
        echo "${pid_priority:-999} $pid"
    done | sort -n | awk '{print $2}')

    for pid in ${(f)sorted_pids}; do
        local model
        model="$(jq -r --arg p "$pid" '.[$p].models | keys_unsorted[0] // empty' <<<"$providers")"
        [[ -n "$model" ]] && { selected_model="$pid/$model"; break; }
    done

    local tmp
    tmp="$(jq \
        --argjson providers "$providers" \
        --arg model "$selected_model" '
        .provider = $providers | (if $model != "" then .model = $model else . end)
    ' "$target")" && printf '%s\n' "$tmp" > "$target"
}

pkg.recipe.opencode.configure.mcps() {
    local target="${1:-${DOTFILES}/generic/.config/opencode/opencode.json}"
    local tmp
    tmp="$(jq --argjson mcps "$(ai.mcps)" '.mcp = $mcps' "$target")" && printf '%s\n' "$tmp" > "$target"
}
