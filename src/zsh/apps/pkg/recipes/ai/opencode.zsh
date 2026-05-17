pkg.recipe.define opencode \
    managers="npm" \
    npm="opencode-ai@latest"


pkg.recipe.opencode.configure() {
    registry.is_enabled pkg opencode pkg.recipe || return 0

    tui.task "Configuring opencode..."
    tui.indent.push
    {
        (( $+commands[opencode] )) || { tui.warn "opencode command not found, skipping"; return 0; }
        (( $+commands[jq] )) || { tui.warn "jq command not found, skipping"; return 0; }

        local config_dir="${XDG_CONFIG_HOME}/opencode"
        [[ -d "$config_dir" ]] || mkdir -p "$config_dir"
        local target="${config_dir}/opencode.json"
        tui.step "Updating $target"

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

        config.hydrate "ai/opencode.json.tmpl" \
            --config-json "$(jq -n --argjson p "${providers:-{}}" --arg sm "$selected_model" '{providers: $p, selected_model: $sm}')" \
            --output "$target"

        tui.success "Configuration complete"
    } always {
        tui.indent.pop
    }
}
