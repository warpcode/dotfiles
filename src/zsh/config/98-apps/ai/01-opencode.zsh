# OpenCode Configuration
# IS_WORK is set to 1 when running in a work environment

# Define default models
local work_model="github-copilot/gpt-5-mini"
local personal_model="opencode/grok-code-fast"

if [[ "$IS_WORK" == "1" ]]; then
    # Use GitHub Copilot model for work
    export OPENCODE_MODEL="${OPENCODE_MODEL:-$work_model}"
else
    # Use OpenCode Grok model for personal use
    export OPENCODE_MODEL="${OPENCODE_MODEL:-$personal_model}"
fi
