# Docker AI Provider - Local inference, no auth
# https://github.com/go-skynet/go-llama.cpp

ai.provider.define "docker" \
    "name=Docker (Local Inference)" \
    "base_url=http://localhost:12434/engines/llama.cpp/v1" \
    "openai_compatible=true" \
    "priority=60"

ai.providers.docker.enabled() {
    (( $+commands[docker] )) || return 1
    # Check if docker container is up
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'docker-model-runner'
}
