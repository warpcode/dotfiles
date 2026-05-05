#pkg.recipe.define claude-code \
#    managers="npm" \
#    npm="@anthropic-ai/claude-code"
#
#pkg.recipe.claude_code.enabled() { [[ $(df.os family) != "macos" ]] }
