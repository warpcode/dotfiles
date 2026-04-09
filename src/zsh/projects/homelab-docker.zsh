# Homelab-docker project directory (override in your environment or ~/.zshrc.d/homelab-docker.zsh if needed)
export HOMELAB_DOCKER_DIR="${HOMELAB_DOCKER_DIR:-$HOME/src/homelab-docker}"
export HOMELAB_DOCKER_REPO="${HOMELAB_DOCKER_REPO:-git@github.com:warpcode/homelab-docker.git}"
# homelab-docker project - AI/LLM Environment
# Aligned with dotfiles secret management system (Provider versions take precedence)


if [[ ! -d "$HOMELAB_DOCKER_DIR" ]]; then
  return
fi

# Navigation
alias hd.cd="_git_clone_and_cd \"$HOMELAB_DOCKER_REPO\" \"$HOMELAB_DOCKER_DIR\""

hd.env.gen() {
        set -e
        hd.cd
        {
            env.print.kv "DOCKER_CONTEXT" "remote-docker"
            env.print.kv "BASE_HOSTNAME" "warpcode.co.uk"
            env.print.kv "LITELLM_MASTER_KEY" "$(secrets.resolve 'LITELLM_API_KEY')"
            env.print.var \
                "GEMINI_API_KEY" \
                "GITHUB_API_TOKEN" \
                "GROQ_API_KEY" \
                "OPENAI_API_KEY" \
                "OPENROUTER_API_KEY"
        }  > "$HOMELAB_DOCKER_DIR/.env"
}

