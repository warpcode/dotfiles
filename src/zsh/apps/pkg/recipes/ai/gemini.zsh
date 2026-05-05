pkg.recipe.define gemini-cli \
    managers="npm" \
    npm="@google/gemini-cli"

pkg.recipe.gemini_cli.enabled() { [[ $(df.os family) != "macos" ]] }
