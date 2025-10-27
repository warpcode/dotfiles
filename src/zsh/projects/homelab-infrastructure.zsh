# Homelab-infrastructure project directory (override in your environment or ~/.zshrc.d/homelab-infrastructure.zsh if needed)
: "${HOMELAB_INFRASTRUCTURE_DIR:=$HOME/src/homelab-infrastructure}"
: "${HOMELAB_INFRASTRUCTURE_REPO:=git@github.com:warpcode/homelab-infrastructure.git}"

if [[ ! -d "$HOMELAB_INFRASTRUCTURE_DIR" ]]; then
  return
fi

# Navigation
alias hi.cd="_git_clone_and_cd \"$HOMELAB_INFRASTRUCTURE_REPO\" \"$HOMELAB_INFRASTRUCTURE_DIR\""

# Infrastructure management aliases (assuming Terraform)
alias hi.init="(hi.cd && terraform init)"
alias hi.plan="(hi.cd && terraform plan)"
alias hi.apply="(hi.cd && terraform apply)"
alias hi.destroy="(hi.cd && terraform destroy)"
