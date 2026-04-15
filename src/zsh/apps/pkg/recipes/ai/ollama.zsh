pkg.recipe.define ollama \
    package="ollama" \
    managers="brew mise" \
    models="gemma4:e2b"

pkg.recipe.ollama.configure() {
    # Ensure background jobs don't print PIDs or 'done' messages
    setopt local_options no_monitor

    tui.task "Configuring ollama..."
    tui.indent.push
    {
        (( $+commands[ollama] )) || { tui.warn "ollama command not found, skipping"; return 0; }

        local -a models=( ${=$(pkg.recipe.get ollama models)} )
        local pid url="http://localhost:11434"
        local started_temp=0

        # Ensure server is running before checking models
        if ! curl -sf "$url" >/dev/null 2>&1; then
            tui.info "Starting temporary ollama server..."
            ollama serve >/dev/null 2>&1 & pid=$!
            started_temp=1

            local count=0
            while ! curl -sf "$url" >/dev/null 2>&1 && kill -0 $pid 2>/dev/null; do
                sleep 1
                (( ++count > 60 )) && { tui.error "Timed out waiting for ollama server"; return 1; }
            done
        fi

        {
            local -a installed=( ${${(f)"$(ollama list 2>/dev/null)"}[2,-1]%%[[:space:]]*} )
            local -a missing=( ${models:|installed} )

            if (( ! $#missing )); then
                tui.success "All models already installed: ${(j:, :)models}"
            else
                tui.info "Missing models: ${(j:, :)missing}"
                for m in $missing; do
                    tui.step "Pulling $m..."
                    ollama pull $m || tui.error "Failed to pull $m"
                done
            fi
        } always {
            if (( started_temp && pid )); then
                tui.info "Stopping temporary ollama server..."
                kill $pid 2>/dev/null; wait $pid 2>/dev/null
            fi
        }
    } always {
        tui.indent.pop
    }
}
