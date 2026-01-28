export LITELLM_BASE_URL="${LITELLM_API_ENDPOINT:-http://litellm.ai.warpcode.co.uk}"
export LITELLM_API_ENDPOINT="${LITELLM_API_ENDPOINT:-$LITELLM_BASE_URL/v1}"
export LITELLM_API_BASE="${LITELLM_API_BASE:-$LITELLM_API_ENDPOINT}"
export LITELLM_API_KEY="${LITELLM_API_KEY:-sk-1234}"

##
# Start a temporary LiteLLM server and run a command against it
# Automatically starts litellm on a local port, waits for readiness,
# executes the command, then cleans up the server
# @param command The command to run (with arguments)
# @return Exit code of the command
##
ai.litellm.proxy.wrapper() {
    local port=4000
    local timeout=90

    if [[ $# -eq 0 ]]; then
        echo "Usage: ai.litellm.proxy.wrapper <command> [args...]" >&2
        return 1
    fi

    # Check if LiteLLM is already running on this port
    if curl -s "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
        echo "[ai.litellm] LiteLLM already running on port ${port}"
        "$@"
        return $?
    fi

    # Generate config from OpenRouter free models
    local config_file
    config_file=$(ai.litellm.config.from.openrouter.free)
    if [[ -z "$config_file" ]]; then
        echo "[ai.litellm] Error: Failed to generate LiteLLM config" >&2
        return 1
    fi

    # Lazy load OpenRouter API key
    if [[ -z "$OPENROUTER_API_KEY" ]]; then
        env.lazy.load "OPENROUTER_API_KEY"
    fi

    echo "[ai.litellm] Starting LiteLLM on port ${port}..."
    uvx --with 'litellm[proxy]' litellm --host 127.0.0.1 --port "$port" --config "$config_file" >/dev/null 2>&1 &
    local litellm_pid=$!

    {
        # Wait for server to be up (any response = server is ready)
        local count=0
        while ! curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/health" 2>/dev/null | grep -qE '^[23]'; do
            if ! kill -0 "$litellm_pid" 2>/dev/null; then
                rm -f "$config_file"
                echo "[ai.litellm] Error: LiteLLM failed to start" >&2
                return 1
            fi
            if [[ $count -ge $timeout ]]; then
                rm -f "$config_file"
                echo "[ai.litellm] Error: LiteLLM failed to start within ${timeout}s" >&2
                return 1
            fi
            sleep 1
            count=$((count + 1))
            if [[ $((count % 10)) -eq 0 ]]; then
                echo "[ai.litellm] Still waiting... (${count}s)"
            fi
        done

        echo "[ai.litellm] LiteLLM ready. Running: $@"
        "$@"
    } always {
        # Cleanup: kill the process we started
        if kill -0 "$litellm_pid" 2>/dev/null; then
            echo "[ai.litellm] Stopping LiteLLM..."
            kill "$litellm_pid" 2>/dev/null
            wait "$litellm_pid" 2>/dev/null
        fi
        # Cleanup config file
        rm -f "$config_file"
        # Safety net: kill any stray litellm processes on our port
        pkill -f "litellm.*--port $port" 2>/dev/null
    }
}
