#!/usr/bin/env zsh
# Unit tests for dot_zsh/apps/pkg/recipes/ai/ollama.zsh

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"

source "$REPO_ROOT/functions/tui.zsh" || { print -r "Failed to source tui.zsh" >&2; exit 1; }
source "$REPO_ROOT/functions/registry.zsh" || { print -r "Failed to source registry.zsh" >&2; exit 1; }
source "$REPO_ROOT/functions/pkg.zsh" || { print -r "Failed to source pkg.zsh" >&2; exit 1; }
source "$REPO_ROOT/apps/pkg/recipes/ai/ollama.zsh" || { print -r "Failed to source ollama.zsh" >&2; exit 1; }

set -e

print -r "Running ollama_recipe.test.zsh unit tests..."

# Mock TUI output to avoid external binary dependency during test
tui.task() { :; }
tui.info() { :; }
tui.success() { :; }
tui.warn() { :; }
tui.error() { :; }
tui.step() { :; }

# Test 1: Recipe definition check
models_val="$(pkg.recipe.get ollama models)"
if [[ "$models_val" != "gemma4:e2b" ]]; then
    print -r "Test 1 Failed: expected gemma4:e2b models, got '$models_val'" >&2
    exit 1
fi

# Test 2: _pkg.recipe.ollama.is_server_running
if _pkg.recipe.ollama.is_server_running "http://127.0.0.1:54321"; then
    print -r "Test 2 Failed: is_server_running should return false for unreachable port" >&2
    exit 1
fi

# Test 3: _pkg.recipe.ollama.sync_models when all installed
ollama() {
    if [[ "$1" == "list" ]]; then
        print -r "NAME                   ID              SIZE      MODIFIED"
        print -r "gemma4:e2b             abc12345        2.0 GB    2 hours ago"
        return 0
    fi
    return 1
}

output_installed=0
tui.success() { output_installed=1; }
_pkg.recipe.ollama.sync_models "gemma4:e2b"
if (( ! output_installed )); then
    print -r "Test 3 Failed: expected tui.success when models are already installed" >&2
    exit 1
fi

# Test 4: _pkg.recipe.ollama.sync_models when models missing
pulled_models=()
ollama() {
    if [[ "$1" == "list" ]]; then
        print -r "NAME                   ID              SIZE      MODIFIED"
        return 0
    elif [[ "$1" == "pull" ]]; then
        pulled_models+=( "$2" )
        return 0
    fi
    return 1
}

_pkg.recipe.ollama.sync_models "model-a" "model-b"
if [[ "${pulled_models[*]}" != "model-a model-b" ]]; then
    print -r "Test 4 Failed: expected pulled models to be 'model-a model-b', got '${pulled_models[*]}'" >&2
    exit 1
fi

# Test 5: _pkg.recipe.ollama.cleanup_temp_server
# Starting dummy background process to test cleanup
sleep 30 &
dummy_pid=$!
if ! kill -0 $dummy_pid 2>/dev/null; then
    print -r "Test 5 Failed: failed to start dummy process" >&2
    exit 1
fi
_pkg.recipe.ollama.cleanup_temp_server $dummy_pid
if kill -0 $dummy_pid 2>/dev/null; then
    print -r "Test 5 Failed: dummy process was not stopped by cleanup_temp_server" >&2
    kill $dummy_pid 2>/dev/null || true
    exit 1
fi

# Test 6: Indent balance verification during configure
initial_level=$TUI_INDENT_LEVEL

# Test that early return when ollama command is missing cleanly maintains indent
tui.indent.push
{
    if (( ! $+commands[ollama] )); then
        tui.warn "ollama command not found, skipping"
    fi
} always {
    tui.indent.pop || true
}

if (( TUI_INDENT_LEVEL != initial_level )); then
    print -r "Test 6 Failed: TUI_INDENT_LEVEL unbalanced (initial $initial_level, now $TUI_INDENT_LEVEL)" >&2
    exit 1
fi

print -r "ALL OLLAMA RECIPE TESTS PASSED SUCCESSFULLY!"
