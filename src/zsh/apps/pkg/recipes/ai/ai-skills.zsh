pkg.recipe.define ai-skills \
    managers="npm" \
    npm="skills@latest"

pkg.recipe.ai-skills.configure() {
    registry.is_enabled pkg ai-skills pkg.recipe || return 0
    ai.skills.install "universal"
}
