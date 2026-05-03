#!/usr/bin/env zsh

# tui.zsh - Terminal UI Components for Dotfiles (Delegation Wrapper)
# This file is now a lightweight wrapper around bin/df.tui for backward compatibility.

typeset -gi TUI_INDENT_LEVEL=${TUI_INDENT_LEVEL:-0}

tui.task() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui task "$@" }
tui.start() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui start "$@" }
tui.step() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui step "$@" }
tui.info() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui info "$@" }
tui.success() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui success "$@" }
tui.done() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui done "$@" }
tui.warn() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui warn "$@" }
tui.error() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui error "$@" }
tui.fatal() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui fatal "$@" }
tui.heading() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui heading "$@" }
tui.banner() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui banner "$@" }
tui.progress() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui progress "$@" }
tui.progress.clear() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui progress-clear "$@" }

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
    local old_level=$TUI_INDENT_LEVEL
    tui.indent.push "$delta"
    "$@"
    local ret=$?
    TUI_INDENT_LEVEL=$old_level
    return $ret
}

tui.input() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui input "$@" }
tui.confirm() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui confirm "$@" }
tui.select() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui select "$@" }
tui.multiselect() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui multiselect "$@" }
tui.date() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui date "$@" }
tui.time() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui time "$@" }
tui.preview() { TUI_INDENT_LEVEL=$TUI_INDENT_LEVEL df.tui preview "$@" }
