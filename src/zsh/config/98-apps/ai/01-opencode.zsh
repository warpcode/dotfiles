# OpenCode Configuration
if [[ "$IS_WORK" == "1" ]]; then
    export OPENCODE_MODEL="github-copilot/gpt-4.1"
else
    export OPENCODE_MODEL="opencode/grok-code-fast"
fi
