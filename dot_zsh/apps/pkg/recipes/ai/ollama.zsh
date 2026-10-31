pkg.recipe.define ollama \
    package="ollama" \
    managers="brew mise" \
    deps="libatomic" \
    models="gemma4:e2b"

pkg.recipe.ollama.enabled() { [[ $(df.os family) != "macos" ]] }

_pkg.recipe.ollama.is_server_running() {
    local url="${1:-http://localhost:11434}"
    curl -sf "$url" >/dev/null 2>&1
}

_pkg.recipe.ollama.start_temp_server() {
    local url="${1:-http://localhost:11434}"
    local max_wait="${2:-60}"
    local count=0

    tui.info "Starting temporary ollama server..."
    ollama serve >/dev/null 2>&1 &
    local server_pid=$!

    while ! _pkg.recipe.ollama.is_server_running "$url" && kill -0 $server_pid 2>/dev/null; do
        sleep 1
        if (( ++count > max_wait )); then
            tui.error "Timed out waiting for ollama server"
            kill $server_pid 2>/dev/null; wait $server_pid 2>/dev/null
            return 1
        fi
    done

    REPLY=$server_pid
    return 0
}

_pkg.recipe.ollama.cleanup_temp_server() {
    local pid="$1"
    (( pid )) || return 0

    tui.info "Stopping temporary ollama server..."
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null || true
}

_pkg.recipe.ollama.sync_models() {
    local -a models=( "$@" )
    (( $#models )) || return 0

    local -a installed=( ${${(f)"$(ollama list 2>/dev/null)"}[2,-1]%%[[:space:]]*} )
    local -a missing=( ${models:|installed} )

    if (( ! $#missing )); then
        tui.success "All models already installed: ${(j:, :)models}"
        return 0
    fi

    tui.info "Missing models: ${(j:, :)missing}"
    local m
    for m in $missing; do
        tui.step "Pulling $m..."
        ollama pull $m || tui.error "Failed to pull $m"
    done
}

pkg.recipe.ollama.configure() {
    # Disabled for now
    return 0

    registry.is_enabled pkg ollama pkg.recipe || return 0

    # Ensure background jobs don't print PIDs or 'done' messages
    setopt local_options no_monitor

    tui.task "Configuring ollama..."
    tui.indent.push
    local pid=0 started_temp=0
    {
        if (( ! $+commands[ollama] )); then
            tui.warn "ollama command not found, skipping"
            return 0
        fi

        if [[ -n "$GITHUB_ACTIONS" ]]; then
            tui.info "Skipping model downloads in GitHub Actions"
            return 0
        fi

        local -a models=( ${=$(pkg.recipe.get ollama models)} )
        local url="http://localhost:11434"

        # Ensure server is running before checking models
        if ! _pkg.recipe.ollama.is_server_running "$url"; then
            _pkg.recipe.ollama.start_temp_server "$url" 60 || return 1
            pid=$REPLY
            started_temp=1
        fi

        _pkg.recipe.ollama.sync_models "${models[@]}"
    } always {
        (( started_temp )) && _pkg.recipe.ollama.cleanup_temp_server $pid
        tui.indent.pop
    }
}
