pkg.recipe.define ai_skills \
    managers="npm" \
    npm="skills@latest"

pkg.recipe.ai_skills.configure() {
    registry.is_enabled pkg ai_skills pkg.recipe || return 0
    ai.skills.install "universal"
}
