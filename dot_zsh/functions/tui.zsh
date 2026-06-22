# tui.zsh - Terminal UI Components for Dotfiles (Delegation Wrapper)
# This file is now a lightweight wrapper around bin/df.tui for backward compatibility.

typeset -gi TUI_INDENT_LEVEL=${TUI_INDENT_LEVEL:-0}

# Resolve df.tui binary path relative to this file
typeset -g _tui_bin="df.tui"

tui.task() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" task "$@" }
tui.start() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" start "$@" }
tui.step() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" step "$@" }
tui.info() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" info "$@" }
tui.success() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" success "$@" }
tui.done() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" done "$@" }
tui.warn() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" warn "$@" }
tui.error() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" error "$@" }
tui.fatal() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" fatal "$@" }
tui.heading() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" heading "$@" }
tui.banner() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" banner "$@" }
tui.progress() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" progress "$@" }
tui.progress.clear() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" progress-clear "$@" }

tui.indent.push() {
    local delta="${1:-1}"
    (( TUI_INDENT_LEVEL += delta ))
}
tui.indent.pop() {
    local delta="${1:-1}"
    (( TUI_INDENT_LEVEL -= delta ))
    (( TUI_INDENT_LEVEL < 0 )) && TUI_INDENT_LEVEL=0
}
tui.indent.reset() {
    TUI_INDENT_LEVEL=0
}
tui.with_indent() {
    local delta="${1:-1}"
    shift
    local -i TUI_INDENT_LEVEL=$(( TUI_INDENT_LEVEL + delta ))
    "$@"
}

tui.input() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" input "$@" }
tui.confirm() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" confirm "$@" }
tui.select() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" select "$@" }
tui.multiselect() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" multiselect "$@" }
tui.date() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" date "$@" }
tui.time() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" time "$@" }
tui.preview() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL "$_tui_bin" preview "$@" }
