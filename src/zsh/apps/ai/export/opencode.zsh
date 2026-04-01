# OpenCode Configuration Exporter

ai.export.opencode() {
    local target_file="${1:-generic/.config/opencode/opencode.json}"
    local -a agents_json=()

    # 1. Load everything
    ai.provider.load_all
    ai.mcp.recipe.load_all
    ai.agent.load_all

    # 2. Build Agent definitions
    for aid in "${ai_agent_list[@]}"; do
        local -A details
        # Simulating get_details since typeset -A doesn't work well across functions without eval/upvar
        details[name]="${ai_agents[$aid:name]}"
        details[description]="${ai_agents[$aid:description]}"
        details[task_type]="${ai_agents[$aid:task_type]}"

        # Resolve model from hierarchy
        local model=$(ai.resolve_model "${details[task_type]}")
        
        agents_json+=("  \"$aid\": { \"model\": \"$model\", \"description\": \"${details[description]}\" }")
    done

    # 3. Build MCP section
    local -a mcp_json=()
    for rid in "${ai_mcp_recipe_list[@]}"; do
        ai.mcp.recipe.is_enabled "$rid" || continue
        # Simplify config generation for now
        mcp_json+=("  \"$rid\": { \"command\": \"${ai_mcp_recipes[$rid:command]}\", \"type\": \"${ai_mcp_recipes[$rid:type]}\" }")
    done

    # 4. Generate final file (Simplified for brevity)
    cat <<EOF > "$target_file"
{
  "mcp": {
$(echo "${(j:,\n:)mcp_json}")
  },
  "agents": {
$(echo "${(j:,\n:)agents_json}")
  }
}
EOF
}

ai.resolve_model() {
    local task_type="${1:?}"
    local hierarchy_file="generic/.config/ai/hierarchy.json"
    
    # Simple jq lookup for the first available model in hierarchy
    local models=$(jq -r ".tasks.\"$task_type\"[]" "$hierarchy_file")
    
    for m in ${(f)models}; do
        local provider="${m%%/*}"
        ai.provider.is_enabled "$provider" && { echo "$m"; return 0; }
    done
    
    # Fallback to something safe
    echo "openai/gpt-4o-mini"
}
