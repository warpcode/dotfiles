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
        pkg.recipe.opencode.configure.base "$target"
        pkg.recipe.opencode.configure.providers "$target"
        pkg.recipe.opencode.configure.mcps "$target"

        local skills_file="${DOTFILES_DIR:-${HOME}/.dotfiles}/assets/configs/ai/skills.json"

        # Check if skills manifest exists
        if [[ -f "$skills_file" ]]; then
            local source_dir target_dir
            source_dir=$(jq -r '.local.source // empty' "$skills_file")
            target_dir=$(jq -r '.local.target // empty' "$skills_file")

            if [[ -n "$source_dir" && -n "$target_dir" ]]; then
                # eval to expand ~ in target
                target_dir=$(eval echo "$target_dir")
                tui.step "Linking skills directory"
                config.symlink --force --contents "$source_dir" "$target_dir"
            else
                tui.step "Linking skills directory"
                config.symlink --force --contents "ai/skills" "${HOME}/.agents/skills"
            fi
        else
            tui.step "Linking skills directory"
            config.symlink --force --contents "ai/skills" "${HOME}/.agents/skills"
        fi

        pkg.recipe.opencode.configure.skills "$skills_file"

        tui.success "Configuration complete"
    } always {
        tui.indent.pop
    }
}

pkg.recipe.opencode.configure.skills() {
    local skills_file="${1:-}"
    if [[ ! -f "$skills_file" ]]; then
        tui.warn "Skills manifest not found: $skills_file"
        return 0
    fi

    local repo names name out
    local -a name_args

    # Read remote skills from JSON
    local remote_items
    remote_items=$(jq -c '.remote[]?' "$skills_file")

    if [[ -z "$remote_items" ]]; then
        return 0
    fi

    echo "$remote_items" | while IFS= read -r item; do
        repo=$(echo "$item" | jq -r '.repo // empty')
        [[ -z "$repo" ]] && continue

        name_args=()
        local skills_str
        skills_str=$(echo "$item" | jq -r 'if .skills then (.skills | join(",")) else empty end')

        if [[ -z "$skills_str" || "$skills_str" == "*" ]]; then
            name_args=(--skill "*")
            tui.step "Skills: * (${repo})"
        else
            # Iterate through JSON array
            for name in $(echo "$item" | jq -r '.skills[]?'); do
                name_args+=(--skill "$name")
            done
            tui.step "Skills: ${skills_str} (${repo})"
        fi

        if ! out=$(npx -y skills add "$repo" "${name_args[@]}" -g --agent universal -y < /dev/null 2>&1); then
            tui.error "Failed to install ${repo}"
            echo "$out" | grep -v "█"
        fi
    done
}


pkg.recipe.opencode.configure.base() {
    local config_dir="${XDG_CONFIG_HOME}/opencode"
    local target="${1:-${config_dir}/opencode.json}"
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
    local config_dir="${XDG_CONFIG_HOME}/opencode"
    local target="${1:-${config_dir}/opencode.json}"
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
    local config_dir="${XDG_CONFIG_HOME}/opencode"
    local target="${1:-${config_dir}/opencode.json}"
    local tmp
    tmp="$(jq --argjson mcps "$(ai.mcps)" '.mcp = $mcps' "$target")" && printf '%s\n' "$tmp" > "$target"
}
