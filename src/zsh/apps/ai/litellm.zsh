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

    echo "[ai.litellm] Starting LiteLLM on port ${port}..."
    uvx litellm --host 127.0.0.1 --port "$port" --quiet &
    local litellm_pid=$!

    {
        # Wait for health check
        local count=0
        while ! curl -s "http://127.0.0.1:${port}/health" >/dev/null 2>&1; do
            if ! kill -0 "$litellm_pid" 2>/dev/null; then
                echo "[ai.litellm] Error: LiteLLM failed to start" >&2
                return 1
            fi
            if [[ $count -ge $timeout ]]; then
                echo "[ai.litellm] Error: LiteLLM failed to start within ${timeout}s" >&2
                return 1
            fi
            sleep 0.5
            count=$((count + 1))
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
        # Safety net: kill any stray litellm processes on our port
        pkill -f "litellm.*--port $port" 2>/dev/null
    }
}
