# AI Chat configuration
# ref: https://github.com/sigoden/aichat/wiki/Environment-Variables

# === AI CLI Aliases ===
alias ai.chat='ensure_aichat && aichat'

alias ai.code='ai.opencode'
alias ai.claude='npx -y @anthropic-ai/claude-code'
alias ai.crush='npx -y @charmland/crush@latest'
alias ai.gemini='npx -y @google/gemini-cli'
alias ai.opencode='npx -y opencode-ai@latest'
alias ai.speckit='uvx --from git+https://github.com/github/spec-kit.git specify'
alias ai.speckit.init='ai.speckit init --ignore-agent-tools --script sh --ai opencode --here --force'
