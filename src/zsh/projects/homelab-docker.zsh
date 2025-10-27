# Homelab-docker project directory (override in your environment or ~/.zshrc.d/homelab-docker.zsh if needed)
: "${HOMELAB_DOCKER_DIR:=$HOME/src/homelab-docker}"
: "${HOMELAB_DOCKER_REPO:=git@github.com:warpcode/homelab-docker.git}"

if [[ ! -d "$HOMELAB_DOCKER_DIR" ]]; then
  return
fi

# Navigation
alias hd.cd="hd.ensure && cd \"$HOMELAB_DOCKER_DIR\""
alias hd.ensure="_git_ensure_cloned \"$HOMELAB_DOCKER_REPO\" \"$HOMELAB_DOCKER_DIR\""

