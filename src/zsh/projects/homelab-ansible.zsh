# Homelab-ansible project directory (override in your environment or ~/.zshrc.d/homelab-ansible.zsh if needed)
: "${HOMELAB_ANSIBLE_DIR:=$HOME/src/homelab-ansible}"
: "${HOMELAB_ANSIBLE_REPO:=git@github.com:warpcode/homelab-ansible.git}"

if [[ ! -d "$HOMELAB_ANSIBLE_DIR" ]]; then
  return
fi

# Navigation
alias ha.cd="ha.ensure && pushd \"$HOMELAB_ANSIBLE_DIR\" > /dev/null"

# Ansible management aliases
alias ha.play="ha.cd && ansible-playbook site.yml; popd > /dev/null"
alias ha.ping="ha.cd && ansible all -m ping; popd > /dev/null"
alias ha.ensure="_g_ensure_cloned \"$HOMELAB_ANSIBLE_REPO\" \"$HOMELAB_ANSIBLE_DIR\""