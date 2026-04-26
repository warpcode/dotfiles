pkg.recipe.define opencode \
    managers="npm" \
    npm="opencode-ai@latest"


pkg.recipe.opencode.configure() {
    tui.task "Configuring opencode..."
    tui.indent.push
    {
        (( $+commands[opencode] )) || { tui.warn "opencode command not found, skipping"; return 0; }
        (( $+commands[jq] )) || { tui.warn "jq command not found, skipping"; return 0; }

        local target="${XDG_CONFIG_HOME}/opencode/opencode.json"
        tui.step "Updating $target"
        pkg.recipe.opencode.configure.base "$target"
        pkg.recipe.opencode.configure.providers "$target"
        pkg.recipe.opencode.configure.mcps "$target"

        tui.step "Linking skills directory"
        config.symlink --contents "ai/skills" "${HOME}/.agents/skills"
        pkg.recipe.opencode.configure.skills

        tui.success "Configuration complete"
    } always {
        tui.indent.pop
    }
}

pkg.recipe.opencode.configure.skills() {
    local -a skills=(
        "anthropics/skills:skill-creator"
        "JuliusBrussee/caveman:caveman,caveman-compress,caveman-commit,caveman-help,caveman-review"
    )

    local item repo names name out
    local -a name_args
    for item in "${skills[@]}"; do
        repo="${item%%:*}"
        names="${item#*:}"

        name_args=()
        if [[ "$repo" == "$names" || "$names" == "*" ]]; then
            name_args=(--skill "*")
            tui.step "Skills: * (${repo})"
        else
            # Split comma-separated names into multiple --skill flags
            for name in ${(s:,:)names}; do
                name_args+=(--skill "$name")
            done
            tui.step "Skills: ${names} (${repo})"
        fi

        if ! out=$(npx skills add "$repo" "${name_args[@]}" -g --agent universal -y 2>&1); then
            tui.error "Failed to install ${item}"
            echo "$out" | grep -v "█"
        fi
    done
}


pkg.recipe.opencode.configure.base() {
    local target="${1:-${XDG_CONFIG_HOME}/opencode/opencode.json}"
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
    local target="${1:-${XDG_CONFIG_HOME}/opencode/opencode.json}"
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
    local target="${1:-${XDG_CONFIG_HOME}/opencode/opencode.json}"
    local tmp
    tmp="$(jq --argjson mcps "$(ai.mcps)" '.mcp = $mcps' "$target")" && printf '%s\n' "$tmp" > "$target"
}
