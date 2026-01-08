# Homelab-docker project directory (override in your environment or ~/.zshrc.d/homelab-docker.zsh if needed)
: "${HOMELAB_DOCKER_DIR:=$HOME/src/homelab-docker}"
: "${HOMELAB_DOCKER_REPO:=git@github.com:warpcode/homelab-docker.git}"

# Register lazy-loaded environment variables
env.register "GEMINI_API_KEY" "kp show 'websites/email/google.main' -a gemini_api_key" 'kp.login'
env.register "GITHUB_API_KEY" "kp show 'KeePassXC-Browser Passwords/Github' -a api_key_docker_ai" 'kp.login'
env.register "GROQ_API_KEY" "kp show 'KeePassXC-Browser Passwords/Groq' -a api_key_docker" 'kp.login'
env.register "OPENAI_API_KEY" "kp show 'KeePassXC-Browser Passwords/OpenRouter' -a api_key_docker" 'kp.login'
env.register "OPENROUTER_API_KEY" "kp show 'KeePassXC-Browser Passwords/ChatGPT' -a api_key_docker_ai" 'kp.login'

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
            env.print.kv "LITELLM_MASTER_KEY" "${LITELLM_API_KEY}"
            env.print.var \
                "GEMINI_API_KEY" \
                "GITHUB_API_KEY" \
                "GROQ_API_KEY" \
                "OPENAI_API_KEY" \
                "OPENROUTER_API_KEY"
        }  > "$HOMELAB_DOCKER_DIR/.env"
}
