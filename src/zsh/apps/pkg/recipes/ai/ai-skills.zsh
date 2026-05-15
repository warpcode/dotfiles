pkg.recipe.define ai-skills \
    managers="npm" \
    npm="skills@latest"

pkg.recipe.ai-skills.configure() {
    registry.is_enabled pkg ai-skills pkg.recipe || return 0

    tui.task "Configuring ai-skills..."
    tui.indent.push
    {
        (( $+commands[jq] )) || { tui.warn "jq command not found, skipping"; return 0; }
        (( $+commands[npx] )) || { tui.warn "npx command not found, skipping"; return 0; }

        local skills_file="${DOTFILES_DIR:-${HOME}/.dotfiles}/assets/configs/ai/skills.json"

        if [[ ! -f "$skills_file" ]]; then
            tui.warn "Skills manifest not found: $skills_file"
            return 0
        fi

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

        local repo names name out
        local -a name_args

        # Read remote skills from JSON
        local remote_items
        remote_items=$(jq -c '.remote[]?' "$skills_file")

        if [[ -n "$remote_items" ]]; then
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

                # Note: keeping --agent universal so it works with all agents
                if ! out=$(npx -y skills add "$repo" "${name_args[@]}" -g --agent universal -y < /dev/null 2>&1); then
                    tui.error "Failed to install ${repo}"
                    echo "$out" | grep -v "█"
                fi
            done
        fi

        tui.success "Configuration complete"
    } always {
        tui.indent.pop
    }
}
