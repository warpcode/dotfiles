#pkg.recipe.define kilo-cli \
#    managers="npm" \
#    npm="@kilocode/cli"
#
#pkg.recipe.kilo_cli.enabled() { [[ $(df.os family) != "macos" ]] }
