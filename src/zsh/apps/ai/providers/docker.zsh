# Docker AI Provider - Local inference, no auth
# https://github.com/go-skynet/go-llama.cpp

ai.provider.define "docker" \
    "name=Docker (Local Inference)" \
    "base_url=http://localhost:12434/engines/llama.cpp/v1" \
    "openai_compatible=true"

ai.providers.docker.enabled() {
    # Check if docker container is up
    docker ps --format '{{.Names}}' | grep -q 'docker-model-runner'
}
