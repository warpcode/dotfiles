# Ollama Provider - Local LLMs
# https://github.com/ollama/ollama/blob/main/docs/api.md

ai.provider.define "ollama" \
    "name=Ollama (Local)" \
    "base_url=http://localhost:11434/v1" \
    "openai_compatible=true"

ai.providers.ollama.enabled() {
    # Enabled if service is running
    curl -s -o /dev/null -w '%{http_code}' "http://localhost:11434/api/tags" | grep -q '200'
}
