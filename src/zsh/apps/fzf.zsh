
#;
# fzf.cli - Wrapper for fzf that falls back to mise exec if fzf is not installed
#
# Checks if fzf is available in PATH. If not, uses mise exec to run fzf@latest.
#
# $@ - Arguments passed to fzf
#
# Returns:
#   Exit code from fzf
function fzf.cli() {
    mise.exec fzf@latest fzf "$@"
}

# Use fzf for history search
source <(fzf.cli --zsh 2>/dev/null)
