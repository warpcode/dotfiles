# oauth free plan is disabled
# pkg.recipe.define qwen-cli \
#     managers="npm" \
#     npm="@qwen-code/qwen-code@latest"
# 
# pkg.recipe.qwen_cli.enabled() { [[ $(df.os family) != "macos" ]] }
