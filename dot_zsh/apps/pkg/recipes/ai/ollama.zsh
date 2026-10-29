pkg.recipe.define ollama \
    package="ollama" \
    managers="brew mise" \
    deps="libatomic" \
    models="gemma4:e2b"

pkg.recipe.ollama.enabled() { [[ $(df.os family) != "macos" ]] }

_pkg.recipe.ollama.pull_models() {
    local -a models=( "$@" )
    local -a installed=( ${${(f)"$(ollama list 2>/dev/null)"}[2,-1]%%[[:space:]]*} )
    local -a missing=( ${models:|installed} )

    if (( ! $#missing )); then
        tui.success "All models already installed: ${(j:, :)models}"
        return 0
    fi

    tui.info "Missing models: ${(j:, :)missing}"
    for m in $missing; do
        tui.step "Pulling $m..."
        ollama pull $m || tui.error "Failed to pull $m"
    done
}

_pkg.recipe.ollama.sync_models() {
    local -a models=( "$@" )
    local pid=0 url="http://localhost:11434"

    {
        # Ensure server is running before checking models
        if ! curl -sf "$url" >/dev/null 2>&1; then
            tui.info "Starting temporary ollama server..."
            ollama serve >/dev/null 2>&1 & pid=$!

            local count=0
            while ! curl -sf "$url" >/dev/null 2>&1 && kill -0 $pid 2>/dev/null; do
                sleep 1
                (( ++count > 60 )) && { tui.error "Timed out waiting for ollama server"; return 1; }
            done
        fi

        _pkg.recipe.ollama.pull_models "${models[@]}"
    } always {
        if (( pid )); then
            tui.info "Stopping temporary ollama server..."
            kill $pid 2>/dev/null; wait $pid 2>/dev/null
        fi
    }
}

pkg.recipe.ollama.configure() {
    # Disabled for now
    return 0

    registry.is_enabled pkg ollama pkg.recipe || return 0

    # Ensure background jobs don't print PIDs or 'done' messages
    setopt local_options no_monitor

    tui.task "Configuring ollama..."
    tui.indent.push
    {
        (( $+commands[ollama] )) || { tui.warn "ollama command not found, skipping"; return 0; }

        if [[ -n "$GITHUB_ACTIONS" ]]; then
            tui.info "Skipping model downloads in GitHub Actions"
            return 0
        fi

        local -a models=( ${=$(pkg.recipe.get ollama models)} )
        _pkg.recipe.ollama.sync_models "${models[@]}"
    } always {
        tui.indent.pop
    }
}
