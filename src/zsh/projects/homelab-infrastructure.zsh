# Homelab-infrastructure project directory (override in your environment or ~/.zshrc.d/homelab-infrastructure.zsh if needed)
: "${HOMELAB_INFRASTRUCTURE_DIR:=$HOME/src/homelab-infrastructure}"
: "${HOMELAB_INFRASTRUCTURE_REPO:=git@github.com:warpcode/homelab-infrastructure.git}"

if [[ ! -d "$HOMELAB_INFRASTRUCTURE_DIR" ]]; then
  return
fi

# Navigation
alias hi.cd="hi.ensure && pushd \"$HOMELAB_INFRASTRUCTURE_DIR\" > /dev/null"
alias hi.ensure="_g_ensure_cloned \"$HOMELAB_INFRASTRUCTURE_REPO\" \"$HOMELAB_INFRASTRUCTURE_DIR\""

# Infrastructure management aliases (assuming Terraform)
alias hi.init="hi.cd && terraform init; popd > /dev/null"
alias hi.plan="hi.cd && terraform plan; popd > /dev/null"
alias hi.apply="hi.cd && terraform apply; popd > /dev/null"
alias hi.destroy="hi.cd && terraform destroy; popd > /dev/null"