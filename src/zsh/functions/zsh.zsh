# zsh.zsh - Zsh-specific utility functions
#
# Provides utility functions for Zsh shell management

# Reload the Zsh configuration
reload() {
    source ~/.zshrc && echo "🔄 config reloaded"
}
