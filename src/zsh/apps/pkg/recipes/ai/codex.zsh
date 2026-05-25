#pkg.recipe.define codex \
#    managers="npm" \
#    npm="@openai/codex"
#
#pkg.recipe.codex.enabled() { [[ $(df.os family) != "macos" ]] }
