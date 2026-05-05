#pkg.recipe.define pi-coding-agent \
#    managers="npm" \
#    npm="@mariozechner/pi-coding-agent"

#pkg.recipe.pi_coding_agent.enabled() { [[ $(df.os family) != "macos" ]] }
