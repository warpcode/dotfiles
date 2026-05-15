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

        tui.step "Linking skills directory"
        local source_dir target_dir
        source_dir=$(jq -r '.local.source // "ai/skills"' "$skills_file")
        target_dir=$(eval echo "$(jq -r '.local.target // "~/.agents/skills"' "$skills_file")")
        config.symlink --force --contents "$source_dir" "$target_dir"

        local repo skills_str out
        local -a name_args

        while IFS=$'\t' read -r repo skills_str; do
            [[ -z "$repo" ]] && continue

            name_args=()
            if [[ -z "$skills_str" || "$skills_str" == "*" ]]; then
                name_args=(--skill "*")
                tui.step "Skills: * (${repo})"
            else
                for name in ${(s:,:)skills_str}; do
                    name_args+=(--skill "$name")
                done
                tui.step "Skills: ${skills_str} (${repo})"
            fi

            if ! out=$(npx -y skills add "$repo" "${name_args[@]}" -g --agent universal -y < /dev/null 2>&1); then
                tui.error "Failed to install ${repo}"
                echo "$out" | grep -v "█"
            fi
        done < <(jq -r '.remote[]? | "\(.repo)\t\(.skills | join(",") // "")"' "$skills_file")

        tui.success "Configuration complete"
    } always {
        tui.indent.pop
    }
}
