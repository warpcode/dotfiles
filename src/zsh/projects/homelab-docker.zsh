# Homelab-docker project directory (override in your environment or ~/.zshrc.d/homelab-docker.zsh if needed)
: "${HOMELAB_DOCKER_DIR:=$HOME/src/homelab-docker}"
: "${HOMELAB_DOCKER_REPO:=git@github.com:warpcode/homelab-docker.git}"

if [[ ! -d "$HOMELAB_DOCKER_DIR" ]]; then
  return
fi

# Navigation
alias hd.cd="_git_clone_and_cd \"$HOMELAB_DOCKER_REPO\" \"$HOMELAB_DOCKER_DIR\""

hd.env.gen() {
    (
        set -e
        hd.cd
        kp.login
        {
            _env_kv "DOCKER_CONTEXT" "remote-docker"
            _env_kv "BASE_HOSTNAME" "warpcode.co.uk"
            _env_kv "LITELLM_MASTER_KEY" "${LITELLM_API_KEY}"
            _env_kv "GEMINI_API_KEY" "$(kp show 'websites/email/google.main' -a gemini_api_key)"
            _env_kv "GITHUB_API_KEY" "$(kp show 'KeePassXC-Browser Passwords/Github' -a api_key_docker_ai)"
            _env_kv "GROQ_API_KEY" "$(kp show 'KeePassXC-Browser Passwords/Groq' -a api_key_docker)"
            _env_kv "OPENAI_API_KEY" "$(kp show 'KeePassXC-Browser Passwords/OpenRouter' -a api_key_docker)"
            _env_kv "OPENROUTER_API_KEY" "$(kp show 'KeePassXC-Browser Passwords/ChatGPT' -a api_key_docker_ai)"
        }  > "$HOMELAB_DOCKER_DIR/.env"
    )
}
